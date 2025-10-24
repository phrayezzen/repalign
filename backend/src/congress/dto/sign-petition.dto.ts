import { IsOptional, IsString, IsBoolean, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class SignPetitionDto {
  @ApiProperty({ required: false, description: 'Optional comment when signing the petition', example: 'I support this cause because...' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  comment?: string;

  @ApiProperty({ required: false, default: true, description: 'Whether the signature should be public' })
  @IsOptional()
  @IsBoolean()
  isPublic?: boolean = true;
}
