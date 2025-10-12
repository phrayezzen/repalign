import { MigrationInterface, QueryRunner } from "typeorm";

export class AddEventDetailFields1728076800000 implements MigrationInterface {
    name = 'AddEventDetailFields1728076800000'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`
            ALTER TABLE "events"
            ADD COLUMN "event_end_date" TIMESTAMP NULL,
            ADD COLUMN "event_address" VARCHAR NULL,
            ADD COLUMN "event_duration" VARCHAR NULL,
            ADD COLUMN "event_format" VARCHAR NULL,
            ADD COLUMN "event_note" TEXT NULL,
            ADD COLUMN "event_detailed_description" TEXT NULL,
            ADD COLUMN "hero_image_url" VARCHAR NULL,
            ADD COLUMN "organizer_followers" INTEGER NULL,
            ADD COLUMN "organizer_events_count" INTEGER NULL,
            ADD COLUMN "organizer_years_active" INTEGER NULL
        `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`
            ALTER TABLE "events"
            DROP COLUMN "event_end_date",
            DROP COLUMN "event_address",
            DROP COLUMN "event_duration",
            DROP COLUMN "event_format",
            DROP COLUMN "event_note",
            DROP COLUMN "event_detailed_description",
            DROP COLUMN "hero_image_url",
            DROP COLUMN "organizer_followers",
            DROP COLUMN "organizer_events_count",
            DROP COLUMN "organizer_years_active"
        `);
    }
}