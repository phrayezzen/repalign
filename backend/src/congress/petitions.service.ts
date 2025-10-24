import { Injectable, NotFoundException, BadRequestException, ConflictException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Petition, PetitionStatus } from './entities/petition.entity';
import { PetitionSignature } from './entities/petition-signature.entity';
import { User } from '../users/entities/user.entity';
import { PetitionQueryDto, PetitionSortBy } from './dto/petition-query.dto';
import { CreatePetitionDto } from './dto/create-petition.dto';
import { SignPetitionDto } from './dto/sign-petition.dto';
import { PetitionDto, PetitionListResponseDto } from './dto/petition-response.dto';

@Injectable()
export class PetitionsService {
  private readonly logger = new Logger(PetitionsService.name);

  constructor(
    @InjectRepository(Petition)
    private petitionRepository: Repository<Petition>,
    @InjectRepository(PetitionSignature)
    private signatureRepository: Repository<PetitionSignature>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
  ) {}

  async findAll(query: PetitionQueryDto, userId?: string): Promise<PetitionListResponseDto> {
    const { page = 1, limit = 20, search, status, category, mine, sortBy } = query;
    const offset = (page - 1) * limit;

    const queryBuilder = this.petitionRepository
      .createQueryBuilder('petition')
      .leftJoinAndSelect('petition.creator', 'creator')
      .leftJoinAndSelect('petition.signatures', 'signatures');

    // Apply filters
    if (search) {
      queryBuilder.andWhere(
        '(petition.title ILIKE :search OR petition.description ILIKE :search)',
        { search: `%${search}%` }
      );
    }

    if (status) {
      queryBuilder.andWhere('petition.status = :status', { status });
    } else {
      // By default, only show active petitions
      queryBuilder.andWhere('petition.status = :status', { status: PetitionStatus.ACTIVE });
    }

    if (category) {
      queryBuilder.andWhere('petition.category = :category', { category });
    }

    if (mine && userId) {
      queryBuilder.andWhere('petition.creatorId = :userId', { userId });
    }

    // Apply sorting
    switch (sortBy) {
      case PetitionSortBy.SIGNATURES:
        queryBuilder.orderBy('(SELECT COUNT(*) FROM petition_signatures WHERE petition_id = petition.id)', 'DESC');
        break;
      case PetitionSortBy.DEADLINE:
        queryBuilder.orderBy('petition.deadline', 'ASC', 'NULLS LAST');
        break;
      case PetitionSortBy.POPULAR:
        // Popular = most signatures in last 7 days
        queryBuilder
          .addSelect(
            '(SELECT COUNT(*) FROM petition_signatures WHERE petition_id = petition.id AND signed_at > NOW() - INTERVAL \'7 days\')',
            'recent_signatures'
          )
          .orderBy('recent_signatures', 'DESC');
        break;
      case PetitionSortBy.CREATED_AT:
      default:
        queryBuilder.orderBy('petition.createdAt', 'DESC');
        break;
    }

    // Get total count
    const total = await queryBuilder.getCount();

    // Apply pagination
    queryBuilder.skip(offset).take(limit);

    const petitions = await queryBuilder.getMany();

    // Check which petitions the user has signed
    let userSignatures: Set<string> = new Set();
    if (userId) {
      const signatures = await this.signatureRepository.find({
        where: { userId },
        select: ['petitionId'],
      });
      userSignatures = new Set(signatures.map(s => s.petitionId));
    }

    // Determine featured petition (most signatures in active petitions)
    const featuredId = petitions.length > 0 ? petitions[0].id : null;

    const items = petitions.map(petition =>
      PetitionDto.fromEntity(
        petition,
        userSignatures.has(petition.id),
        petition.id === featuredId
      )
    );

    return {
      items,
      total,
      page,
      limit,
      hasMore: offset + limit < total,
    };
  }

  async findOne(id: string, userId?: string): Promise<PetitionDto> {
    const petition = await this.petitionRepository.findOne({
      where: { id },
      relations: ['creator', 'signatures', 'signatures.user'],
    });

    if (!petition) {
      throw new NotFoundException(`Petition with ID ${id} not found`);
    }

    let userHasSigned = false;
    if (userId) {
      const signature = await this.signatureRepository.findOne({
        where: { petitionId: id, userId },
      });
      userHasSigned = !!signature;
    }

    return PetitionDto.fromEntity(petition, userHasSigned);
  }

  async create(createPetitionDto: CreatePetitionDto, userId: string): Promise<PetitionDto> {
    // Verify user exists
    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Validate deadline is in the future
    if (createPetitionDto.deadline && createPetitionDto.deadline < new Date()) {
      throw new BadRequestException('Deadline must be in the future');
    }

    const petition = this.petitionRepository.create({
      ...createPetitionDto,
      creatorId: userId,
      status: PetitionStatus.ACTIVE,
    });

    const savedPetition = await this.petitionRepository.save(petition);

    // Load creator relation
    const petitionWithCreator = await this.petitionRepository.findOne({
      where: { id: savedPetition.id },
      relations: ['creator'],
    });

    return PetitionDto.fromEntity(petitionWithCreator);
  }

  async sign(petitionId: string, userId: string, signDto: SignPetitionDto): Promise<{ message: string; currentSignatures: number }> {
    const petition = await this.petitionRepository.findOne({
      where: { id: petitionId },
      relations: ['signatures'],
    });

    if (!petition) {
      throw new NotFoundException(`Petition with ID ${petitionId} not found`);
    }

    if (!petition.canBeSigned()) {
      throw new BadRequestException('This petition is not accepting signatures');
    }

    // Check if user already signed
    const existingSignature = await this.signatureRepository.findOne({
      where: { petitionId, userId },
    });

    if (existingSignature) {
      throw new ConflictException('You have already signed this petition');
    }

    // Create signature
    const signature = this.signatureRepository.create({
      petitionId,
      userId,
      comment: signDto.comment,
      isPublic: signDto.isPublic ?? true,
    });

    await this.signatureRepository.save(signature);

    // Check if petition reached goal
    const updatedPetition = await this.petitionRepository.findOne({
      where: { id: petitionId },
      relations: ['signatures'],
    });

    if (updatedPetition.isSuccessful && updatedPetition.status === PetitionStatus.ACTIVE) {
      updatedPetition.markAsSuccessful();
      await this.petitionRepository.save(updatedPetition);
    }

    return {
      message: 'Petition signed successfully',
      currentSignatures: updatedPetition.currentSignatures,
    };
  }

  async unsign(petitionId: string, userId: string): Promise<{ message: string; currentSignatures: number }> {
    const petition = await this.petitionRepository.findOne({
      where: { id: petitionId },
    });

    if (!petition) {
      throw new NotFoundException(`Petition with ID ${petitionId} not found`);
    }

    const signature = await this.signatureRepository.findOne({
      where: { petitionId, userId },
    });

    if (!signature) {
      throw new NotFoundException('You have not signed this petition');
    }

    await this.signatureRepository.remove(signature);

    // Get updated signature count
    const updatedPetition = await this.petitionRepository.findOne({
      where: { id: petitionId },
      relations: ['signatures'],
    });

    return {
      message: 'Signature removed successfully',
      currentSignatures: updatedPetition.currentSignatures,
    };
  }

  async getSignatures(petitionId: string): Promise<any[]> {
    const signatures = await this.signatureRepository.find({
      where: { petitionId, isPublic: true },
      relations: ['user'],
      order: { signedAt: 'DESC' },
      take: 100, // Limit to recent 100 signatures
    });

    return signatures.map(sig => ({
      id: sig.id,
      userName: sig.user?.displayName || 'Anonymous',
      userAvatar: sig.user?.profileImageUrl,
      comment: sig.comment,
      signedAt: sig.signedAt,
    }));
  }
}
