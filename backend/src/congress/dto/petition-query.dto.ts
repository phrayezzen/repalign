import { IsOptional, IsString, IsEnum, IsInt, Min, Max, IsBoolean } from 'class-validator';
import { Transform } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';
import { PetitionStatus, PetitionCategory } from '../entities/petition.entity';

export enum PetitionSortBy {
  CREATED_AT = 'createdAt',
  SIGNATURES = 'signatures',
  DEADLINE = 'deadline',
  POPULAR = 'popular',
}

export class PetitionQueryDto {
  @ApiProperty({ required: false, description: 'Search by title or description' })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiProperty({ required: false, enum: PetitionStatus, description: 'Filter by status' })
  @IsOptional()
  @IsEnum(PetitionStatus)
  status?: PetitionStatus;

  @ApiProperty({ required: false, enum: PetitionCategory, description: 'Filter by category' })
  @IsOptional()
  @IsEnum(PetitionCategory)
  category?: PetitionCategory;

  @ApiProperty({ required: false, description: 'Show only petitions created by current user' })
  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  mine?: boolean;

  @ApiProperty({ required: false, enum: PetitionSortBy, default: PetitionSortBy.CREATED_AT, description: 'Sort by field' })
  @IsOptional()
  @IsEnum(PetitionSortBy)
  sortBy?: PetitionSortBy = PetitionSortBy.CREATED_AT;

  @ApiProperty({ required: false, default: 1, description: 'Page number' })
  @IsOptional()
  @Transform(({ value }) => parseInt(value))
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiProperty({ required: false, default: 20, description: 'Number of results per page' })
  @IsOptional()
  @Transform(({ value }) => parseInt(value))
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;
}
