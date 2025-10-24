import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ThrottlerModule } from '@nestjs/throttler';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { DatabaseConfig } from './config/database.config';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { PostsModule } from './posts/posts.module';
import { CongressModule } from './congress/congress.module';
import { GamificationModule } from './gamification/gamification.module';
import { FeedModule } from './feed/feed.module';
import { HealthModule } from './health/health.module';

// Import all entities explicitly
import { User } from './users/entities/user.entity';
import { CitizenProfile } from './users/entities/citizen-profile.entity';
import { LegislatorProfile } from './users/entities/legislator-profile.entity';
import { UserInterest } from './users/entities/user-interest.entity';
import { Post } from './posts/entities/post.entity';
import { Comment } from './posts/entities/comment.entity';
import { Like } from './posts/entities/like.entity';
import { Follow } from './posts/entities/follow.entity';
import { Bill } from './congress/entities/bill.entity';
import { Vote } from './congress/entities/vote.entity';
import { Event } from './congress/entities/event.entity';
import { EventParticipant } from './congress/entities/event-participant.entity';
import { Petition } from './congress/entities/petition.entity';
import { PetitionSignature } from './congress/entities/petition-signature.entity';
import { CampaignContributor } from './congress/entities/campaign-contributor.entity';
import { Legislator } from './congress/entities/legislator.entity';
import { LegislatorFollow } from './congress/entities/legislator-follow.entity';
import { CommitteeMembership } from './congress/entities/committee-membership.entity';
import { PressRelease } from './congress/entities/press-release.entity';
import { Media } from './posts/entities/media.entity';
import { Activity } from './gamification/entities/activity.entity';

@Module({
  imports: [
    // Configuration
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),

    // Database
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => {
        const isSqlite = configService.get('DATABASE_TYPE') === 'sqlite';

        const entities = [
          User,
          CitizenProfile,
          LegislatorProfile,
          UserInterest,
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
          LegislatorFollow,
          CommitteeMembership,
          PressRelease,
          Activity,
        ];

        if (isSqlite) {
          return {
            type: 'sqlite',
            database: configService.get('DATABASE_NAME') || './repalign_dev.db',
            entities,
            synchronize: configService.get('NODE_ENV') === 'development',
            logging: configService.get('NODE_ENV') === 'development',
          };
        }

        // Support both DATABASE_URL (Railway) and individual variables
        const databaseUrl = configService.get('DATABASE_URL');
        if (databaseUrl) {
          return {
            type: 'postgres',
            url: databaseUrl,
            entities,
            synchronize: configService.get('NODE_ENV') === 'production',
            logging: true,  // Enable logging to debug Railway issues
            migrations: [__dirname + '/database/migrations/*{.ts,.js}'],
            migrationsRun: false,  // Disable auto-migrations for now
          };
        }

        return {
          type: 'postgres',
          host: configService.get('DATABASE_HOST'),
          port: configService.get('DATABASE_PORT'),
          username: configService.get('DATABASE_USERNAME'),
          password: configService.get('DATABASE_PASSWORD'),
          database: configService.get('DATABASE_NAME'),
          entities,
          synchronize: configService.get('NODE_ENV') === 'development',
          logging: configService.get('NODE_ENV') === 'development',
          migrations: [__dirname + '/database/migrations/*{.ts,.js}'],
          migrationsRun: true,
        };
      },
      inject: [ConfigService],
    }),

    // Rate limiting
    ThrottlerModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => [
        {
          ttl: configService.get('RATE_LIMIT_TTL') || 60,
          limit: configService.get('RATE_LIMIT_LIMIT') || 100,
        },
      ],
      inject: [ConfigService],
    }),

    // Feature modules
    HealthModule,
    AuthModule,
    UsersModule,
    PostsModule,
    CongressModule,
    GamificationModule,
    FeedModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}