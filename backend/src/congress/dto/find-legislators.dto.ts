import { IsOptional, IsString, IsEnum, IsInt, Min, Max } from 'class-validator';
import { Transform } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

export class FindLegislatorsDto {
  @ApiProperty({ required: false, description: 'Filter by state (e.g., CA, NY)' })
  @IsOptional()
  @IsString()
  @Transform(({ value }) => value?.toUpperCase())
  state?: string;

  @ApiProperty({ required: false, enum: ['house', 'senate'], description: 'Filter by chamber' })
  @IsOptional()
  @IsEnum(['house', 'senate'])
  chamber?: 'house' | 'senate';

  @ApiProperty({ required: false, description: 'Filter by party' })
  @IsOptional()
  @IsString()
  party?: string;

  @ApiProperty({ required: false, description: 'Search by name' })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiProperty({ required: false, default: 50, description: 'Number of results to return' })
  @IsOptional()
  @Transform(({ value }) => parseInt(value))
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 50;

  @ApiProperty({ required: false, default: 0, description: 'Number of results to skip' })
  @IsOptional()
  @Transform(({ value }) => parseInt(value))
  @IsInt()
  @Min(0)
  offset?: number = 0;
}