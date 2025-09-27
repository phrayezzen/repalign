import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsEnum, IsNotEmpty, IsOptional, IsString, MinLength } from 'class-validator';
import { UserType } from '../../users/entities/user.entity';

export class RegisterDto {
  @ApiProperty({
    description: 'Unique username',
    example: 'johndoe123',
  })
  @IsString()
  @IsNotEmpty()
  username: string;

  @ApiProperty({
    description: 'User email address',
    example: 'john.doe@example.com',
  })
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiProperty({
    description: 'User password (minimum 8 characters)',
    example: 'SecurePassword123!',
  })
  @IsString()
  @MinLength(8)
  password: string;

  @ApiProperty({
    description: 'Display name for the user',
    example: 'John Doe',
  })
  @IsString()
  @IsNotEmpty()
  displayName: string;

  @ApiProperty({
    description: 'User type',
    enum: UserType,
    example: UserType.CITIZEN,
  })
  @IsEnum(UserType)
  userType: UserType;

  @ApiProperty({
    description: 'User location',
    example: 'New York, NY',
  })
  @IsString()
  @IsNotEmpty()
  location: string;

  @ApiProperty({
    description: 'User bio (optional)',
    example: 'Passionate about civic engagement and democracy.',
    required: false,
  })
  @IsString()
  @IsOptional()
  bio?: string;
}