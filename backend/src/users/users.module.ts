import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { OnboardingController } from './onboarding.controller';
import { OnboardingService } from './onboarding.service';
import { User } from './entities/user.entity';
import { CitizenProfile } from './entities/citizen-profile.entity';
import { LegislatorProfile } from './entities/legislator-profile.entity';
import { UserInterest } from './entities/user-interest.entity';
import { Follow } from '../posts/entities/follow.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      CitizenProfile,
      LegislatorProfile,
      UserInterest,
      Follow,
    ]),
  ],
  controllers: [UsersController, OnboardingController],
  providers: [UsersService, OnboardingService],
  exports: [UsersService, OnboardingService],
})
export class UsersModule {}