import { ApiProperty } from '@nestjs/swagger';
import { Petition, PetitionStatus, PetitionCategory } from '../entities/petition.entity';

export class PetitionDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  title: string;

  @ApiProperty()
  description: string;

  @ApiProperty({ enum: PetitionCategory })
  category: PetitionCategory;

  @ApiProperty()
  targetSignatures: number;

  @ApiProperty()
  currentSignatures: number;

  @ApiProperty()
  progressPercentage: number;

  @ApiProperty({ enum: PetitionStatus })
  status: PetitionStatus;

  @ApiProperty({ required: false })
  deadline?: Date;

  @ApiProperty({ required: false })
  daysRemaining?: number;

  @ApiProperty()
  creatorId: string;

  @ApiProperty()
  creatorName: string;

  @ApiProperty({ required: false })
  creatorAvatar?: string;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;

  @ApiProperty({ required: false })
  userHasSigned?: boolean;

  @ApiProperty({ required: false })
  isFeatured?: boolean;

  static fromEntity(petition: Petition, userHasSigned?: boolean, isFeatured?: boolean): PetitionDto {
    return {
      id: petition.id,
      title: petition.title,
      description: petition.description,
      category: petition.category,
      targetSignatures: petition.targetSignatures,
      currentSignatures: petition.currentSignatures,
      progressPercentage: petition.progressPercentage,
      status: petition.status,
      deadline: petition.deadline,
      daysRemaining: petition.daysRemaining !== Infinity ? petition.daysRemaining : undefined,
      creatorId: petition.creatorId,
      creatorName: petition.creator?.displayName || 'Unknown',
      creatorAvatar: petition.creator?.profileImageUrl,
      createdAt: petition.createdAt,
      updatedAt: petition.updatedAt,
      userHasSigned,
      isFeatured,
    };
  }
}

export class PetitionListResponseDto {
  @ApiProperty({ type: [PetitionDto] })
  items: PetitionDto[];

  @ApiProperty()
  total: number;

  @ApiProperty()
  page: number;

  @ApiProperty()
  limit: number;

  @ApiProperty()
  hasMore: boolean;
}
