import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  UseGuards,
  ParseUUIDPipe,
  ParseIntPipe,
  DefaultValuePipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserType } from './entities/user.entity';

@ApiTags('users')
@Controller('users')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  @ApiOperation({ summary: 'Get all users with pagination and filtering' })
  @ApiQuery({ name: 'page', required: false, description: 'Page number' })
  @ApiQuery({ name: 'limit', required: false, description: 'Items per page' })
  @ApiQuery({ name: 'search', required: false, description: 'Search query' })
  @ApiQuery({ name: 'userType', required: false, enum: UserType })
  @ApiResponse({ status: 200, description: 'List of users' })
  async findAll(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number,
    @Query('search') search?: string,
    @Query('userType') userType?: UserType,
  ) {
    return this.usersService.findAll(page, Math.min(limit, 50), search, userType);
  }

  @Get('search')
  @ApiOperation({ summary: 'Search users' })
  @ApiQuery({ name: 'q', description: 'Search query' })
  @ApiQuery({ name: 'userType', required: false, enum: UserType })
  @ApiQuery({ name: 'limit', required: false, description: 'Max results' })
  @ApiResponse({ status: 200, description: 'Search results' })
  async search(
    @Query('q') query: string,
    @Query('userType') userType?: UserType,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit?: number,
  ) {
    return this.usersService.searchUsers(query, userType, Math.min(limit, 50));
  }

  @Get('legislators')
  @ApiOperation({ summary: 'Get all legislators' })
  @ApiResponse({ status: 200, description: 'List of legislators' })
  async getLegislators() {
    return this.usersService.getLegislators();
  }

  @Get('legislators/:bioguideId')
  @ApiOperation({ summary: 'Get legislator by bioguide ID' })
  @ApiResponse({ status: 200, description: 'Legislator found' })
  @ApiResponse({ status: 404, description: 'Legislator not found' })
  async getLegislatorByBioguideId(@Param('bioguideId') bioguideId: string) {
    return this.usersService.getLegislatorByBioguideId(bioguideId);
  }

  @Get('me')
  @ApiOperation({ summary: 'Get current user profile' })
  @ApiResponse({ status: 200, description: 'Current user profile' })
  async getCurrentUser(@CurrentUser() currentUser: any) {
    return this.usersService.findById(currentUser.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get user by ID' })
  @ApiResponse({ status: 200, description: 'User found' })
  @ApiResponse({ status: 404, description: 'User not found' })
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.usersService.findById(id);
  }

  @Patch('me')
  @ApiOperation({ summary: 'Update current user profile' })
  @ApiResponse({ status: 200, description: 'User updated successfully' })
  @ApiResponse({ status: 400, description: 'Bad Request' })
  async updateCurrentUser(
    @CurrentUser() currentUser: any,
    @Body() updateUserDto: UpdateUserDto,
  ) {
    return this.usersService.update(currentUser.id, updateUserDto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update user by ID (admin only)' })
  @ApiResponse({ status: 200, description: 'User updated successfully' })
  @ApiResponse({ status: 404, description: 'User not found' })
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateUserDto: UpdateUserDto,
  ) {
    return this.usersService.update(id, updateUserDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete user by ID (admin only)' })
  @ApiResponse({ status: 200, description: 'User deleted successfully' })
  @ApiResponse({ status: 404, description: 'User not found' })
  async remove(@Param('id', ParseUUIDPipe) id: string) {
    return this.usersService.remove(id);
  }

  @Post(':id/follow')
  @ApiOperation({ summary: 'Follow a user' })
  @ApiResponse({ status: 201, description: 'User followed successfully' })
  async followUser(@Param('id', ParseUUIDPipe) targetUserId: string, @CurrentUser() currentUser: any) {
    return this.usersService.followUser(currentUser.id, targetUserId);
  }

  @Delete(':id/follow')
  @ApiOperation({ summary: 'Unfollow a user' })
  @ApiResponse({ status: 200, description: 'User unfollowed successfully' })
  async unfollowUser(@Param('id', ParseUUIDPipe) targetUserId: string, @CurrentUser() currentUser: any) {
    return this.usersService.unfollowUser(currentUser.id, targetUserId);
  }

  @Get(':id/followers')
  @ApiOperation({ summary: 'Get user follower count' })
  @ApiResponse({ status: 200, description: 'Follower count' })
  async getFollowerCount(@Param('id', ParseUUIDPipe) userId: string) {
    return this.usersService.getFollowerCount(userId);
  }

  @Get(':id/following/:targetId')
  @ApiOperation({ summary: 'Check if user is following another user' })
  @ApiResponse({ status: 200, description: 'Following status' })
  async isFollowing(@Param('id', ParseUUIDPipe) userId: string, @Param('targetId', ParseUUIDPipe) targetUserId: string) {
    return this.usersService.isFollowing(userId, targetUserId);
  }
}