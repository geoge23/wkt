import { model, Mongoose, Schema } from "mongoose";

export interface wktUserInterface {
    userId: string,
    lastWorkout: {
        date: string,
        type: string
    },
    workoutList: string[],
    workouts: {
        [x: string]: {
            name: string,
            reps: number,
            sets: number
        }[]
    },
    data: {
        [y: string]: {
            weight: number,
            reps: number,
            date: number,
            set: number
        }[]
    }
}

export interface wktActionInterface {
    userId: string,
    machine: string,
    weight: number,
    reps: number,
    set: number,
    date: number
}

const wktUserSchema = new Schema<wktUserInterface>({
    userId: {
        type: String,
        unique: true
    },
    workoutList: [String],
    lastWorkout: Object,
    workouts: Object,
    data: Object
})

const wktActionSchema = new Schema<wktActionInterface>({
    userId: String,
    weight: Number,
    reps: Number,
    set: Number,
    date: Number,
    machine: String
})

export const wktUser = model<wktUserInterface>('wkts', wktUserSchema)
export const wktAction = model<wktActionInterface>('wkt-actions', wktActionSchema)