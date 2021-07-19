import { model, Mongoose, Schema } from "mongoose";

export interface wktUserInterface {
    userId: string,
    lastWorkout: {
        day: `${number}-${number}-${number}`,
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
    userId: String,
    workoutList: [String],
    lastWorkout: {
        type: {
            day: String,
            type: String
        }
    },
    workouts: Object,
    data: Object
})

export const wktUser = model<wktUserInterface>('wkts', wktUserSchema)