import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { User } from './entities/user.entity';
import { CitizenProfile } from './entities/citizen-profile.entity';
import { LegislatorProfile } from './entities/legislator-profile.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, CitizenProfile, LegislatorProfile]),
  ],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}