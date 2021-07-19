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

export const wktUser = model<wktUserInterface>('wkts', wktUserSchema)