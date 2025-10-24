import { IsNotEmpty, IsString, IsEnum, IsInt, Min, IsOptional, IsArray, IsDate, MinLength, MaxLength } from 'class-validator';
import { Transform, Type } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';
import { PetitionCategory } from '../entities/petition.entity';

export class CreatePetitionDto {
  @ApiProperty({ description: 'Petition title', example: 'Demand UPS provide Air Conditioning to all drivers' })
  @IsNotEmpty()
  @IsString()
  @MinLength(10)
  @MaxLength(200)
  title: string;

  @ApiProperty({ description: 'Detailed description of the petition', example: 'We demand UPS install working air conditioning in all delivery trucks...' })
  @IsNotEmpty()
  @IsString()
  @MinLength(50)
  @MaxLength(10000)
  description: string;

  @ApiProperty({ enum: PetitionCategory, description: 'Category of the petition' })
  @IsNotEmpty()
  @IsEnum(PetitionCategory)
  category: PetitionCategory;

  @ApiProperty({ description: 'Target number of signatures', example: 10000, minimum: 100 })
  @IsNotEmpty()
  @IsInt()
  @Min(100)
  targetSignatures: number;

  @ApiProperty({ required: false, description: 'Deadline for the petition (ISO 8601 date)', example: '2024-12-31T23:59:59Z' })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  deadline?: Date;

  @ApiProperty({ required: false, description: 'Array of legislator IDs to send petition to', example: ['legislator-id-1', 'legislator-id-2'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  recipientLegislatorIds?: string[];
}
