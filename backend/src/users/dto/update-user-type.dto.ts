import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty } from 'class-validator';
import { UserType } from '../entities/user.entity';

export class UpdateUserTypeDto {
  @ApiProperty({
    description: 'User type selection',
    enum: UserType,
    example: UserType.CITIZEN,
  })
  @IsEnum(UserType)
  @IsNotEmpty()
  userType: UserType;
}
