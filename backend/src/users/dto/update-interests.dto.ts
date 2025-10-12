import { ApiProperty } from '@nestjs/swagger';
import { IsArray, IsEnum, ArrayMinSize } from 'class-validator';
import { CauseType } from '../entities/user-interest.entity';

export class UpdateInterestsDto {
  @ApiProperty({
    description: 'List of causes the user is interested in (minimum 3)',
    enum: CauseType,
    isArray: true,
    example: [
      CauseType.CLIMATE_ENVIRONMENT,
      CauseType.HEALTHCARE,
      CauseType.VOTING_RIGHTS,
    ],
  })
  @IsArray()
  @IsEnum(CauseType, { each: true })
  @ArrayMinSize(3, {
    message: 'Please select at least 3 causes',
  })
  causes: CauseType[];
}
