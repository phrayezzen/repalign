import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserType } from './entities/user.entity';
import { UserInterest, CauseType } from './entities/user-interest.entity';
import { UpdateUserTypeDto } from './dto/update-user-type.dto';
import { UpdateLocationDto } from './dto/update-location.dto';
import { UpdateInterestsDto } from './dto/update-interests.dto';
import { UsersService } from './users.service';

@Injectable()
export class OnboardingService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(UserInterest)
    private userInterestRepository: Repository<UserInterest>,
    private usersService: UsersService,
  ) {}

  async updateUserType(userId: string, dto: UpdateUserTypeDto): Promise<User> {
    const user = await this.userRepository.findOne({ where: { id: userId } });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    user.userType = dto.userType;
    return await this.userRepository.save(user);
  }

  async updateLocation(userId: string, dto: UpdateLocationDto): Promise<User> {
    const user = await this.userRepository.findOne({ where: { id: userId } });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    user.state = dto.state;
    user.congressionalDistrict = dto.congressionalDistrict || null;
    user.city = dto.city;

    // Update legacy location field for backwards compatibility
    user.location = `${dto.city}, ${dto.state}`;

    return await this.userRepository.save(user);
  }

  async updateInterests(userId: string, dto: UpdateInterestsDto): Promise<UserInterest[]> {
    const user = await this.userRepository.findOne({ where: { id: userId } });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Remove existing interests
    await this.userInterestRepository.delete({ userId });

    // Create new interests
    const interests = dto.causes.map((cause) =>
      this.userInterestRepository.create({
        userId,
        cause,
      }),
    );

    return await this.userInterestRepository.save(interests);
  }

  async completeOnboarding(userId: string): Promise<User> {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: ['interests'],
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Validate that all onboarding steps are complete
    if (!user.userType) {
      throw new BadRequestException('User type is required');
    }

    if (!user.state || !user.city) {
      throw new BadRequestException('Location information is required');
    }

    if (!user.interests || user.interests.length < 3) {
      throw new BadRequestException('At least 3 interests are required');
    }

    // Mark onboarding as complete
    user.onboardingCompleted = true;

    // Create profile based on user type
    if (user.userType === UserType.CITIZEN && !user.citizenProfile) {
      await this.usersService.createCitizenProfile(user.id);
    }
    // Note: Legislator and Organization profiles may require additional verification

    return await this.userRepository.save(user);
  }

  async getOnboardingStatus(userId: string) {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: ['interests'],
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return {
      userId: user.id,
      onboardingCompleted: user.onboardingCompleted,
      steps: {
        userType: !!user.userType,
        location: !!(user.state && user.city),
        interests: user.interests && user.interests.length >= 3,
      },
      currentData: {
        userType: user.userType,
        state: user.state,
        congressionalDistrict: user.congressionalDistrict,
        city: user.city,
        interests: user.interests?.map((i) => i.cause) || [],
      },
    };
  }
}
