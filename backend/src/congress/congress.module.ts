import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Bill } from './entities/bill.entity';
import { Vote } from './entities/vote.entity';
import { Event } from './entities/event.entity';
import { CampaignContributor } from './entities/campaign-contributor.entity';
import { Legislator } from './entities/legislator.entity';
import { LegislatorsController } from './legislators.controller';
import { LegislatorsService } from './legislators.service';
import { CongressApiService } from './congress-api.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Bill, Vote, Event, CampaignContributor, Legislator]),
  ],
  controllers: [LegislatorsController],
  providers: [LegislatorsService, CongressApiService],
  exports: [LegislatorsService, CongressApiService],
})
export class CongressModule {}