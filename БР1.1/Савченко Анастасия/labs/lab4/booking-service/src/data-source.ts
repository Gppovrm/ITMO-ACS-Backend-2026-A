import "reflect-metadata"
import { DataSource } from "typeorm"
import { Booking } from "./models/booking.entity"
import { Review } from "./models/review.entity"

export const AppDataSource = new DataSource({
  type: "postgres",
  host: process.env.DB_HOST || "localhost",
  port: Number(process.env.DB_PORT) || 5432,
  username: process.env.DB_USER || "postgres",
  password: process.env.DB_PASS || "postgres",
  database: process.env.DB_NAME || "booking_db",
  synchronize: true,
  entities: [Booking, Review]
})