import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddSocialFeatures1727904240000 implements MigrationInterface {
  name = 'AddSocialFeatures1727904240000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Create media table
    await queryRunner.query(`
      CREATE TABLE "media" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "url" character varying NOT NULL,
        "media_type" character varying NOT NULL,
        "mime_type" character varying NOT NULL,
        "file_size" integer NOT NULL,
        "original_filename" character varying,
        "alt" character varying,
        "caption" character varying,
        "uploaded_by" character varying NOT NULL,
        "associated_post_id" character varying,
        "width" integer,
        "height" integer,
        "duration" integer,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_f4e0fcac36e050de337b670d8bd" PRIMARY KEY ("id")
      )
    `);

    // Create petitions table
    await queryRunner.query(`
      CREATE TABLE "petitions" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "title" character varying NOT NULL,
        "petition_description" text NOT NULL,
        "target_signatures" integer,
        "current_signatures" integer NOT NULL DEFAULT 0,
        "petition_status" character varying NOT NULL DEFAULT 'active',
        "target_audience" character varying,
        "deadline" TIMESTAMP,
        "creator_user_id" character varying NOT NULL,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_b8d62e13b5e43108a0a1d26eade" PRIMARY KEY ("id")
      )
    `);

    // Create petition_signatures table
    await queryRunner.query(`
      CREATE TABLE "petition_signatures" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "petition_id" character varying NOT NULL,
        "user_id" character varying NOT NULL,
        "comment" text,
        "is_public" boolean NOT NULL DEFAULT true,
        "signed_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_b5ad35a0dbff7eda1c5ea84d726" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_petition_user" UNIQUE ("petition_id", "user_id")
      )
    `);

    // Create event_participants table
    await queryRunner.query(`
      CREATE TABLE "event_participants" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "event_id" character varying NOT NULL,
        "user_id" character varying NOT NULL,
        "status" character varying NOT NULL DEFAULT 'interested',
        "registered_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_b45e4a69acf7556fb7a95ca8a90" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_event_user" UNIQUE ("event_id", "user_id")
      )
    `);

    // Update posts table with new columns
    await queryRunner.query(`
      ALTER TABLE "posts"
      ADD COLUMN "post_type" character varying NOT NULL DEFAULT 'text',
      ADD COLUMN "shared_event_id" character varying,
      ADD COLUMN "shared_petition_id" character varying,
      ADD COLUMN "tags" text NOT NULL DEFAULT '',
      ADD COLUMN "attachment_urls" text NOT NULL DEFAULT ''
    `);

    // Update events table with new columns
    await queryRunner.query(`
      ALTER TABLE "events"
      ADD COLUMN "creator_user_id" character varying NOT NULL DEFAULT '',
      ADD COLUMN "featured_legislator_ids" text NOT NULL DEFAULT '',
      ADD COLUMN "max_attendees" integer,
      ADD COLUMN "current_attendees" integer NOT NULL DEFAULT 0,
      ADD COLUMN "registration_url" character varying,
      ADD COLUMN "is_virtual" boolean NOT NULL DEFAULT false,
      ADD COLUMN "virtual_link" character varying
    `);

    // Create indexes
    await queryRunner.query(`CREATE INDEX "IDX_media_uploaded_by" ON "media" ("uploaded_by")`);
    await queryRunner.query(`CREATE INDEX "IDX_media_associated_post_id" ON "media" ("associated_post_id")`);
    await queryRunner.query(`CREATE INDEX "IDX_media_type" ON "media" ("media_type")`);
    await queryRunner.query(`CREATE INDEX "IDX_media_created_at" ON "media" ("created_at")`);

    await queryRunner.query(`CREATE INDEX "IDX_petitions_creator_user_id" ON "petitions" ("creator_user_id")`);
    await queryRunner.query(`CREATE INDEX "IDX_petitions_status" ON "petitions" ("petition_status")`);
    await queryRunner.query(`CREATE INDEX "IDX_petitions_deadline" ON "petitions" ("deadline")`);
    await queryRunner.query(`CREATE INDEX "IDX_petitions_created_at" ON "petitions" ("created_at")`);

    await queryRunner.query(`CREATE INDEX "IDX_petition_signatures_petition_id" ON "petition_signatures" ("petition_id")`);
    await queryRunner.query(`CREATE INDEX "IDX_petition_signatures_user_id" ON "petition_signatures" ("user_id")`);
    await queryRunner.query(`CREATE INDEX "IDX_petition_signatures_signed_at" ON "petition_signatures" ("signed_at")`);

    await queryRunner.query(`CREATE INDEX "IDX_event_participants_event_id" ON "event_participants" ("event_id")`);
    await queryRunner.query(`CREATE INDEX "IDX_event_participants_user_id" ON "event_participants" ("user_id")`);
    await queryRunner.query(`CREATE INDEX "IDX_event_participants_status" ON "event_participants" ("status")`);
    await queryRunner.query(`CREATE INDEX "IDX_event_participants_registered_at" ON "event_participants" ("registered_at")`);

    await queryRunner.query(`CREATE INDEX "IDX_posts_post_type" ON "posts" ("post_type")`);
    await queryRunner.query(`CREATE INDEX "IDX_posts_shared_event_id" ON "posts" ("shared_event_id")`);
    await queryRunner.query(`CREATE INDEX "IDX_posts_shared_petition_id" ON "posts" ("shared_petition_id")`);

    // Add foreign key constraints
    await queryRunner.query(`
      ALTER TABLE "media"
      ADD CONSTRAINT "FK_media_uploaded_by"
      FOREIGN KEY ("uploaded_by") REFERENCES "users"("id") ON DELETE CASCADE
    `);

    await queryRunner.query(`
      ALTER TABLE "media"
      ADD CONSTRAINT "FK_media_associated_post_id"
      FOREIGN KEY ("associated_post_id") REFERENCES "posts"("id") ON DELETE CASCADE
    `);

    await queryRunner.query(`
      ALTER TABLE "petitions"
      ADD CONSTRAINT "FK_petitions_creator_user_id"
      FOREIGN KEY ("creator_user_id") REFERENCES "users"("id") ON DELETE CASCADE
    `);

    await queryRunner.query(`
      ALTER TABLE "petition_signatures"
      ADD CONSTRAINT "FK_petition_signatures_petition_id"
      FOREIGN KEY ("petition_id") REFERENCES "petitions"("id") ON DELETE CASCADE
    `);

    await queryRunner.query(`
      ALTER TABLE "petition_signatures"
      ADD CONSTRAINT "FK_petition_signatures_user_id"
      FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE
    `);

    await queryRunner.query(`
      ALTER TABLE "event_participants"
      ADD CONSTRAINT "FK_event_participants_event_id"
      FOREIGN KEY ("event_id") REFERENCES "events"("id") ON DELETE CASCADE
    `);

    await queryRunner.query(`
      ALTER TABLE "event_participants"
      ADD CONSTRAINT "FK_event_participants_user_id"
      FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE
    `);

    await queryRunner.query(`
      ALTER TABLE "posts"
      ADD CONSTRAINT "FK_posts_shared_event_id"
      FOREIGN KEY ("shared_event_id") REFERENCES "events"("id")
    `);

    await queryRunner.query(`
      ALTER TABLE "posts"
      ADD CONSTRAINT "FK_posts_shared_petition_id"
      FOREIGN KEY ("shared_petition_id") REFERENCES "petitions"("id")
    `);

    await queryRunner.query(`
      ALTER TABLE "events"
      ADD CONSTRAINT "FK_events_creator_user_id"
      FOREIGN KEY ("creator_user_id") REFERENCES "users"("id") ON DELETE CASCADE
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Remove foreign key constraints
    await queryRunner.query(`ALTER TABLE "events" DROP CONSTRAINT "FK_events_creator_user_id"`);
    await queryRunner.query(`ALTER TABLE "posts" DROP CONSTRAINT "FK_posts_shared_petition_id"`);
    await queryRunner.query(`ALTER TABLE "posts" DROP CONSTRAINT "FK_posts_shared_event_id"`);
    await queryRunner.query(`ALTER TABLE "event_participants" DROP CONSTRAINT "FK_event_participants_user_id"`);
    await queryRunner.query(`ALTER TABLE "event_participants" DROP CONSTRAINT "FK_event_participants_event_id"`);
    await queryRunner.query(`ALTER TABLE "petition_signatures" DROP CONSTRAINT "FK_petition_signatures_user_id"`);
    await queryRunner.query(`ALTER TABLE "petition_signatures" DROP CONSTRAINT "FK_petition_signatures_petition_id"`);
    await queryRunner.query(`ALTER TABLE "petitions" DROP CONSTRAINT "FK_petitions_creator_user_id"`);
    await queryRunner.query(`ALTER TABLE "media" DROP CONSTRAINT "FK_media_associated_post_id"`);
    await queryRunner.query(`ALTER TABLE "media" DROP CONSTRAINT "FK_media_uploaded_by"`);

    // Drop indexes
    await queryRunner.query(`DROP INDEX "IDX_posts_shared_petition_id"`);
    await queryRunner.query(`DROP INDEX "IDX_posts_shared_event_id"`);
    await queryRunner.query(`DROP INDEX "IDX_posts_post_type"`);
    await queryRunner.query(`DROP INDEX "IDX_event_participants_registered_at"`);
    await queryRunner.query(`DROP INDEX "IDX_event_participants_status"`);
    await queryRunner.query(`DROP INDEX "IDX_event_participants_user_id"`);
    await queryRunner.query(`DROP INDEX "IDX_event_participants_event_id"`);
    await queryRunner.query(`DROP INDEX "IDX_petition_signatures_signed_at"`);
    await queryRunner.query(`DROP INDEX "IDX_petition_signatures_user_id"`);
    await queryRunner.query(`DROP INDEX "IDX_petition_signatures_petition_id"`);
    await queryRunner.query(`DROP INDEX "IDX_petitions_created_at"`);
    await queryRunner.query(`DROP INDEX "IDX_petitions_deadline"`);
    await queryRunner.query(`DROP INDEX "IDX_petitions_status"`);
    await queryRunner.query(`DROP INDEX "IDX_petitions_creator_user_id"`);
    await queryRunner.query(`DROP INDEX "IDX_media_created_at"`);
    await queryRunner.query(`DROP INDEX "IDX_media_type"`);
    await queryRunner.query(`DROP INDEX "IDX_media_associated_post_id"`);
    await queryRunner.query(`DROP INDEX "IDX_media_uploaded_by"`);

    // Remove columns from events table
    await queryRunner.query(`
      ALTER TABLE "events"
      DROP COLUMN "virtual_link",
      DROP COLUMN "is_virtual",
      DROP COLUMN "registration_url",
      DROP COLUMN "current_attendees",
      DROP COLUMN "max_attendees",
      DROP COLUMN "featured_legislator_ids",
      DROP COLUMN "creator_user_id"
    `);

    // Remove columns from posts table
    await queryRunner.query(`
      ALTER TABLE "posts"
      DROP COLUMN "attachment_urls",
      DROP COLUMN "tags",
      DROP COLUMN "shared_petition_id",
      DROP COLUMN "shared_event_id",
      DROP COLUMN "post_type"
    `);

    // Drop tables
    await queryRunner.query(`DROP TABLE "event_participants"`);
    await queryRunner.query(`DROP TABLE "petition_signatures"`);
    await queryRunner.query(`DROP TABLE "petitions"`);
    await queryRunner.query(`DROP TABLE "media"`);
  }
}