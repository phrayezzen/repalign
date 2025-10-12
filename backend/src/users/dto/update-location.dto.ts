import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class UpdateLocationDto {
  @ApiProperty({
    description: 'State',
    example: 'NY',
  })
  @IsString()
  @IsNotEmpty()
  state: string;

  @ApiProperty({
    description: 'Congressional district (optional)',
    example: '5',
    required: false,
  })
  @IsString()
  @IsOptional()
  congressionalDistrict?: string;

  @ApiProperty({
    description: 'City or town',
    example: 'New York',
  })
  @IsString()
  @IsNotEmpty()
  city: string;
}
