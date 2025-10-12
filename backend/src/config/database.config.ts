import { DataSource, DataSourceOptions } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import { config } from 'dotenv';

// Import all entities explicitly
import { User } from '../users/entities/user.entity';
import { CitizenProfile } from '../users/entities/citizen-profile.entity';
import { LegislatorProfile } from '../users/entities/legislator-profile.entity';
import { Post } from '../posts/entities/post.entity';
import { Comment } from '../posts/entities/comment.entity';
import { Like } from '../posts/entities/like.entity';
import { Follow } from '../posts/entities/follow.entity';
import { Media } from '../posts/entities/media.entity';
import { Bill } from '../congress/entities/bill.entity';
import { Vote } from '../congress/entities/vote.entity';
import { Event } from '../congress/entities/event.entity';
import { EventParticipant } from '../congress/entities/event-participant.entity';
import { Petition } from '../congress/entities/petition.entity';
import { PetitionSignature } from '../congress/entities/petition-signature.entity';
import { CampaignContributor } from '../congress/entities/campaign-contributor.entity';
import { Legislator } from '../congress/entities/legislator.entity';
import { Activity } from '../gamification/entities/activity.entity';

config();

const configService = new ConfigService();

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

const isSqlite = configService.get('DATABASE_TYPE') === 'sqlite';

const dataSourceOptions: DataSourceOptions = isSqlite
  ? {
      type: 'sqlite',
      database: configService.get('DATABASE_NAME') || './repalign_dev.db',
      entities,
      migrations: [__dirname + '/../migrations/*{.ts,.js}'],
      synchronize: configService.get('NODE_ENV') === 'development',
      logging: configService.get('NODE_ENV') === 'development',
    }
  : {
      type: 'postgres',
      host: configService.get('DATABASE_HOST'),
      port: configService.get('DATABASE_PORT'),
      username: configService.get('DATABASE_USERNAME'),
      password: configService.get('DATABASE_PASSWORD'),
      database: configService.get('DATABASE_NAME'),
      entities,
      migrations: [__dirname + '/../migrations/*{.ts,.js}'],
      synchronize: configService.get('NODE_ENV') === 'development',
      logging: configService.get('NODE_ENV') === 'development',
    };

export const DatabaseConfig = new DataSource(dataSourceOptions);

// Default export for TypeORM CLI
export default DatabaseConfig;