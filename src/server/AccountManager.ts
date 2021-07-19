import mongoose from 'mongoose'
import express from 'express'
import JWT from 'jsonwebtoken'
import bcrypt from 'bcrypt'

declare global {
    namespace Express {
        interface Request {
            user: UserInterface
        }
    }
}

interface UserInterface {
    _id?: string,
    username: string,
    password: string,
    meta: any,
    permissions: string[]
}

const UserSchema = new mongoose.Schema<UserInterface>({
    username: {type: String, required: true},
    password: {type: String, required: true},
    meta: {type: Object, required: true},
    permissions: {type: Array, required: true}
})

const User = mongoose.model<UserInterface>('users', UserSchema)

export default class AccountManager {
    private _jwtToken = "";
    private _redirectFlag = "";

    constructor({jwtToken, redirectOnFailDestination}: {jwtToken: string, redirectOnFailDestination?: string}) {
        this._jwtToken = jwtToken
        this._redirectFlag = redirectOnFailDestination || '';
    }

    public authMiddleware = (async (req: express.Request, res: express.Response, next: Function) => {
        let udoc: any = {};
        let UserDoc: any = {};
        let jwt = '';
        try {
            jwt = req.headers['authorization']!
            jwt = jwt!.replace('Bearer ', '');
        } catch (e) {
            console.log(`[Auth] User at ${req.ip} attempted to connect but did not provide a JWT in the Authorization header`)
            if (this._redirectFlag) {
                res.redirect(this._redirectFlag!)
            } else {
                res.status(401).send({
                    status: 'error',
                    reason: 'Your client is not providing a JWT in the Authorization header'
                })
            }
        }
        try {
            udoc = JWT.verify(jwt, this._jwtToken);
        } catch (e) {
            console.error('[Error]', e)
            res.status(401).send({
                status: 'error',
                reason: 'Request\'s JWT appears to be forged. Check your JWT environment variable. You may need to relaunch the server'
            })
        }
        try {
            UserDoc = await User.findOne({_id: udoc.id})
        } catch (e) {
            console.error('[Error]', e)
            res.status(500).send({
                status: 'error',
                reason: 'JWT is valid but could not find user with matching ID. Check log for details'
            })
        }
        req.user = UserDoc;
        next();
    })

    async performAuth(username: string, password: string): Promise<{
        jwt: string,
        doc: UserInterface
    }> {
        return new Promise<{
            jwt: string,
            doc: UserInterface
        }>(async (y,n) => {
            const user = await User.findOne({username})
            if (await bcrypt.compare(password, user!.password)) {
                const newJwt = JWT.sign({id: user!._id}, this._jwtToken)
                y({jwt: newJwt, doc: user!})
            } else {
                n(new Error("Password incorrect"))
            }
        })
    }

    async addUser(username: string, password: string, meta: any = {}, permissions: string[] = []) {
        const userDoc: UserInterface = {
            username,
            password: await bcrypt.hash(password, 10),
            meta,
            permissions
        }
        await (new User(userDoc)).save()
    }

    async setMeta(id: string, meta: string, value: any) {
        await User.updateOne({_id: id}, {
            $set: {
                [`meta.${meta}`]: value
            }
        })
    }
}
