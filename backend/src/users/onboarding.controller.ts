import {
  Controller,
  Patch,
  Post,
  Get,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { OnboardingService } from './onboarding.service';
import { UpdateUserTypeDto } from './dto/update-user-type.dto';
import { UpdateLocationDto } from './dto/update-location.dto';
import { UpdateInterestsDto } from './dto/update-interests.dto';

@ApiTags('onboarding')
@Controller('users/me/onboarding')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class OnboardingController {
  constructor(private onboardingService: OnboardingService) {}

  @Get('status')
  @ApiOperation({ summary: 'Get onboarding status' })
  @ApiResponse({ status: 200, description: 'Onboarding status retrieved' })
  async getOnboardingStatus(@CurrentUser() user: any) {
    return this.onboardingService.getOnboardingStatus(user.id);
  }

  @Patch('user-type')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Update user type (Step 2)' })
  @ApiResponse({ status: 200, description: 'User type updated successfully' })
  @ApiResponse({ status: 400, description: 'Invalid user type' })
  async updateUserType(
    @CurrentUser() user: any,
    @Body() dto: UpdateUserTypeDto,
  ) {
    const updatedUser = await this.onboardingService.updateUserType(user.id, dto);

    return {
      message: 'User type updated successfully',
      userType: updatedUser.userType,
    };
  }

  @Patch('location')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Update location information (Step 3)' })
  @ApiResponse({ status: 200, description: 'Location updated successfully' })
  @ApiResponse({ status: 400, description: 'Invalid location data' })
  async updateLocation(
    @CurrentUser() user: any,
    @Body() dto: UpdateLocationDto,
  ) {
    const updatedUser = await this.onboardingService.updateLocation(user.id, dto);

    return {
      message: 'Location updated successfully',
      location: {
        state: updatedUser.state,
        congressionalDistrict: updatedUser.congressionalDistrict,
        city: updatedUser.city,
      },
    };
  }

  @Patch('interests')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Update user interests/causes (Step 4)' })
  @ApiResponse({ status: 200, description: 'Interests updated successfully' })
  @ApiResponse({ status: 400, description: 'Invalid interests data' })
  async updateInterests(
    @CurrentUser() user: any,
    @Body() dto: UpdateInterestsDto,
  ) {
    const interests = await this.onboardingService.updateInterests(user.id, dto);

    return {
      message: 'Interests updated successfully',
      interests: interests.map((i) => i.cause),
    };
  }

  @Post('complete')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Complete onboarding process' })
  @ApiResponse({ status: 200, description: 'Onboarding completed successfully' })
  @ApiResponse({
    status: 400,
    description: 'Onboarding requirements not met',
  })
  async completeOnboarding(@CurrentUser() user: any) {
    const updatedUser = await this.onboardingService.completeOnboarding(user.id);

    return {
      message: 'Onboarding completed successfully',
      user: {
        id: updatedUser.id,
        username: updatedUser.username,
        email: updatedUser.email,
        displayName: updatedUser.displayName,
        userType: updatedUser.userType,
        state: updatedUser.state,
        city: updatedUser.city,
        congressionalDistrict: updatedUser.congressionalDistrict,
        onboardingCompleted: updatedUser.onboardingCompleted,
      },
    };
  }
}
