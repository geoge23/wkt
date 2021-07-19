import express from 'express'
import Mongoose from 'mongoose'
import AccountManager from './AccountManager'
import moment from 'moment'
import { wktUser, wktUserInterface } from './models'
require('dotenv').config()

const app = express();
Mongoose.connect(process.env.MONGO_URI!, {
    useUnifiedTopology: true,
    useNewUrlParser: true,
})
const am = new AccountManager({
    jwtToken: process.env.JWT_TOKEN!
});

app.post('/auth/login', express.json(), async (req, res) => {
    const { username, password } = req.body
    try {
        const {jwt, doc} = await am.performAuth(username, password)
        if (!doc.meta.usedWkt) {
            const newWktDoc: wktUserInterface = {
                userId: doc._id!,
                workoutList: [],
                lastWorkout: {
                    day: '0-0-0000',
                    type: 'null'
                },
                workouts: {},
                data: {}
            } 
            const newWktUser = new wktUser(newWktDoc)
            console.log(newWktUser, await newWktUser.save())
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
        workouts: wktDoc!.workouts
    }
    if (wktDoc!.lastWorkout.day == todaysDate) {
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
app.post('/workout', am.authMiddleware, express.json(), async (req, res) => {
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
app.delete('/workout', am.authMiddleware, express.json(), async (req, res) => {
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

app.post('/workout/machine', am.authMiddleware, express.json(), async (req, res) => {
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
app.delete('/workout/machine', am.authMiddleware, express.json(), async (req, res) => {
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

//TODO: Fix this
app.post('/action', am.authMiddleware, express.json(), async (req, res) => {
    try {
        const {workout, machine, weight, reps, set}: {workout: string, machine: string, weight: number, reps: number, set: number} = req.body;
        const wktDoc = await wktUser.findOne({userId: req.user._id!})
        const todaysDate = moment().format('M-D-YYYY')
        console.log(todaysDate)
        if (wktDoc!.lastWorkout.day != todaysDate) {
            wktDoc!.updateOne({"$set": {"lastWorkout.day": todaysDate, "lastWorkout.type": workout}}).then(e => console.log(e))
        }
        wktDoc!.updateOne({"$addToSet": {
            [`data.${machine}`]: {
                weight,
                reps,
                set,
                date: moment().unix()
            }
        }})
        res.status(200).send({status: 'success'})
    } catch (e) {
        res.status(500).send({status:'error',reason:e})
    }
})

app.listen(process.env.PORT, () => {console.log(`listening on ${process.env.PORT}`)})
