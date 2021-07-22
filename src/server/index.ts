import express from 'express'
import Mongoose from 'mongoose'
import { body, validationResult } from 'express-validator';
import AccountManager from './AccountManager'
import moment from 'moment'
import { wktUser, wktUserInterface, wktAction, wktActionInterface } from './models'
require('dotenv').config()

const app = express();
Mongoose.connect(process.env.MONGO_URI!, {
    useUnifiedTopology: true,
    useNewUrlParser: true,
})
const am = new AccountManager({
    jwtToken: process.env.JWT_TOKEN!
});

const validationMiddleware = (req: express.Request, res: express.Response, next: Function) => {
    const errors = validationResult(req);
    const results = errors.formatWith(
        ({param, msg}) => {
            return `${param}: ${msg}`
        }
    )
    if (!errors.isEmpty()) {
        res.status(400).json({ status: 'error', reason: results.array().join(', ')});
    } else {
        next()
    }
}

app.post('/auth/login', express.json(), body('username').isString(), body('password').isString(), validationMiddleware, async (req, res) => {
    const { username, password } = req.body
    try {
        const {jwt, doc} = await am.performAuth(username, password)
        if (!doc.meta.usedWkt) {
            const newWktDoc = {
                userId: doc._id!,
                workoutList: []
            } 
            const newWktUser = new wktUser(newWktDoc)
            newWktUser.markModified('lastWorkout')
            console.log(newWktDoc)
            await newWktUser.save()
            am.setMeta(doc._id!, 'usedWkt', true)
        }
        res.status(200).send({
            status: 'success',
            jwt
        })
    } catch (e) {
        console.log(e)
        if (e.toString().indexOf('Password incorrect') != -1) {
            res.status(401).send({
                status: 'error',
                reason: 'Your password is incorrect'
            })
        } else {
            res.status(401).send({
                status: 'error',
                reason: e
            })
        }
    }
})
app.get('/auth/test', am.authMiddleware, async (req, res) => {
    const wktDoc = await wktUser.findOne({userId: req.user._id!})
    res.status(200).send({status: 'success', data: wktDoc})
})

app.get('/workout', am.authMiddleware, async (req, res) => {
    const id = req.user._id!;
    const wktDoc = await wktUser.findOne({userId: id})
    if (wktDoc === null) {
        res.status(400).send({
            status: 'error',
            reason: 'Your wkt doc is missing. Try removing the usedWkt flag from your user MongoDB document'
        })
    }
    const todaysDate = moment().format('M-D-YYYY')
    const returnDoc = {
        status: 'success',
        todaysWorkout: '',
        lastWorkout: wktDoc!.lastWorkout.date,
        workouts: wktDoc!.workouts
    }
    if (wktDoc!.lastWorkout.date == todaysDate) {
        returnDoc.todaysWorkout = wktDoc!.lastWorkout.type
    } else if (!(wktDoc!.lastWorkout.type)) {
        returnDoc.todaysWorkout = wktDoc!.workoutList[0]
    } else {
        const index = wktDoc!.workoutList.findIndex((v) => v == wktDoc!.lastWorkout.type)
        if (wktDoc!.workoutList.length - 1 < index) {
            returnDoc.todaysWorkout = wktDoc!.workoutList[0]
        } else {
            returnDoc.todaysWorkout = wktDoc!.workoutList[index + 1]
        }
    }
    res.status(200).send(returnDoc)
})
app.post('/workout', am.authMiddleware, express.json(), body('name').isString(), body('exercises').isArray(), validationMiddleware, async (req, res) => {
    try {
        const {name, exercises}: {name: string, exercises: {
            name: string,
            reps: number,
            sets: number
        }[]} = req.body;
        const id = req.user._id!;
        await wktUser.updateOne({userId: id}, 
            {
                "$set": {
                    [`workouts.${name}`]: exercises
                },
                "$addToSet": {
                    workoutList: name
                }
            }
        )
        res.status(200).send({status: 'success'})
    } catch (e) {
        console.log(e)
        res.status(500).send({status:'error',reason:e})
    }
})
app.delete('/workout', am.authMiddleware, express.json(), body('name').isString(), validationMiddleware, async (req, res) => {
    try {
        const {name}: {name: string} = req.body;
        const id = req.user._id!;
        await wktUser.updateOne({userId: id}, 
            {
                "$unset": {
                    [`workouts.${name}`]: ""
                },
                "$pull": {
                    workoutList: name
                }
            }
    )
        res.status(200).send({status: 'success'})
    } catch (e) {
        console.log(e)
        res.status(500).send({status:'error',reason:e})
    }
})

app.post('/workout/machine', am.authMiddleware, express.json(), body('workout').isString(), body('machine').isObject(), validationMiddleware, async (req, res) => {
    try {
        const {workout, machine}: {workout: string, machine: {
            name: string,
            reps: number,
            sets: number
        }} = req.body;
        const id = req.user._id!;
        await wktUser.updateOne({userId: id}, {"$addToSet": {
            [`workouts.${workout}`]: machine
        }})
        res.status(200).send({status: 'success'})
    } catch (e) {
        console.log(e)
        res.status(500).send({status:'error',reason:e})
    }
})
app.delete('/workout/machine', am.authMiddleware, express.json(), body('workout').isString(), body('machineName').isString(), validationMiddleware, async (req, res) => {
    try {
        const {workout, machineName}: {workout: string, machineName: string} = req.body;
        const id = req.user._id!;
        await wktUser.updateOne({userId: id}, {"$pull": {
            [`workouts.${workout}`]: {
                name: machineName
            }
        }})
        res.status(200).send({status: 'success'})
    } catch (e) {
        console.log(e)
        res.status(500).send({status:'error',reason:e})
    }
})

app.post(
    '/action', 
    am.authMiddleware, 
    express.json(), 
    body('workout').isString(), 
    body('machine').isString(), 
    body('weight').isNumeric(), 
    body('reps').isNumeric(), 
    body('set').isNumeric(), 
    validationMiddleware,
    async (req, res) => {
        try {
            const {workout, machine, weight, reps, set}: {workout: string, machine: string, weight: number, reps: number, set: number} = req.body;
            const wktDoc = await wktUser.findOne({userId: req.user._id!})
            if (wktDoc == null) {throw new Error('Workout Doc not found. Please set "usedWkt" to false on the user\'s meta object in MongoDB')}
            const todaysDate = moment().format('M-D-YYYY')
            if (!wktDoc!.lastWorkout.date || wktDoc!.lastWorkout.date != todaysDate) {
                wktDoc.lastWorkout = {
                    date: todaysDate,
                    type: workout
                }
                await wktDoc.save()
            }
            if (wktDoc.workoutList.indexOf(workout) == -1) {
                return res.status(400).send({
                    status: 'error',
                    reason: 'The workout specified does not exist'
                })
            }
            if (!(wktDoc.workouts[workout].find(e => e.name == machine))) {
                return res.status(400).send({
                    status: 'error',
                    reason: 'The machine specified does not exist'
                })
            }
            const newMachineData: wktActionInterface = {
                userId: req.user._id!,
                machine,
                weight,
                reps,
                set,
                date: moment().unix()
            }
            const wktActionDoc = new wktAction(newMachineData)
            await wktActionDoc.save()
            res.status(200).send({status: 'success'})
        } catch (e) {
            res.status(500).send({status:'error',reason:e.toString()})
        }
    }
)

app.listen(process.env.PORT, () => {console.log(`listening on ${process.env.PORT}`)})
