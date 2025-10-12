import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';

// Import entities
import { User } from './users/entities/user.entity';
import { CitizenProfile } from './users/entities/citizen-profile.entity';
import { LegislatorProfile } from './users/entities/legislator-profile.entity';
import { Post } from './posts/entities/post.entity';
import { Comment } from './posts/entities/comment.entity';
import { Like } from './posts/entities/like.entity';
import { Follow } from './posts/entities/follow.entity';
import { Media } from './posts/entities/media.entity';
import { Event } from './congress/entities/event.entity';
import { EventParticipant } from './congress/entities/event-participant.entity';
import { Petition } from './congress/entities/petition.entity';
import { PetitionSignature } from './congress/entities/petition-signature.entity';
import { Legislator } from './congress/entities/legislator.entity';
import { Bill } from './congress/entities/bill.entity';
import { Vote } from './congress/entities/vote.entity';
import { CampaignContributor } from './congress/entities/campaign-contributor.entity';
import { Activity } from './gamification/entities/activity.entity';

// Import commands
import { SeedLegislatorsCommand } from './congress/commands/seed-legislators.command';
import { SeedSocialFeaturesCommand } from './database/commands/seed-social-features.command';
import { SimpleSeedCommand } from './database/commands/simple-seed.command';

// Import services
import { CongressApiService } from './congress/congress-api.service';

const entities = [
  User,
  CitizenProfile,
  LegislatorProfile,
  Post,
  Comment,
  Like,
  Follow,
  Media,
  Bill,
  Vote,
  Event,
  EventParticipant,
  Petition,
  PetitionSignature,
  CampaignContributor,
  Legislator,
  Activity,
];

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.DATABASE_HOST,
      port: parseInt(process.env.DATABASE_PORT) || 5432,
      username: process.env.DATABASE_USERNAME,
      password: process.env.DATABASE_PASSWORD,
      database: process.env.DATABASE_NAME,
      entities,
      synchronize: false, // Don't auto-sync in CLI mode
      logging: false,
    }),
    TypeOrmModule.forFeature(entities),
  ],
  providers: [
    SeedLegislatorsCommand,
    SeedSocialFeaturesCommand,
    SimpleSeedCommand,
    CongressApiService,
  ],
})
export class CliModule {}