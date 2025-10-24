import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Bill } from './entities/bill.entity';
import { Vote } from './entities/vote.entity';
import { Event } from './entities/event.entity';
import { CampaignContributor } from './entities/campaign-contributor.entity';
import { Legislator } from './entities/legislator.entity';
import { LegislatorFollow } from './entities/legislator-follow.entity';
import { CommitteeMembership } from './entities/committee-membership.entity';
import { PressRelease } from './entities/press-release.entity';
import { Petition } from './entities/petition.entity';
import { PetitionSignature } from './entities/petition-signature.entity';
import { User } from '../users/entities/user.entity';
import { LegislatorsController } from './legislators.controller';
import { LegislatorsService } from './legislators.service';
import { CongressApiService } from './congress-api.service';
import { PetitionsController } from './petitions.controller';
import { PetitionsService } from './petitions.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Bill,
      Vote,
      Event,
      CampaignContributor,
      Legislator,
      LegislatorFollow,
      CommitteeMembership,
      PressRelease,
      Petition,
      PetitionSignature,
      User,
    ]),
  ],
  controllers: [LegislatorsController, PetitionsController],
  providers: [LegislatorsService, CongressApiService, PetitionsService],
  exports: [LegislatorsService, CongressApiService, PetitionsService],
})
export class CongressModule {}