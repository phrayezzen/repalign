import { Controller, Get, Post, Delete, Param, Body, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { PostsService } from './posts.service';
import { CreateCommentDto } from './dto/create-comment.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('posts')
@Controller('posts')
export class PostsController {
  constructor(private readonly postsService: PostsService) {}

  @Get(':id')
  @ApiOperation({ summary: 'Get post by ID' })
  @ApiResponse({ status: 200, description: 'Post details' })
  async getPost(@Param('id') id: string) {
    return this.postsService.getPostById(id);
  }

  @Get(':id/comments')
  @ApiOperation({ summary: 'Get comments for a post' })
  @ApiResponse({ status: 200, description: 'Post comments' })
  async getPostComments(@Param('id') postId: string) {
    return this.postsService.getPostComments(postId);
  }

  @Post(':id/comments')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a comment on a post' })
  @ApiResponse({ status: 201, description: 'Comment created' })
  async createComment(
    @Param('id') postId: string,
    @Body() createCommentDto: CreateCommentDto,
    @Request() req: any
  ) {
    return this.postsService.createComment(postId, req.user.id, createCommentDto.content);
  }

  @Post(':id/like')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Like a post' })
  @ApiResponse({ status: 200, description: 'Post liked' })
  async likePost(@Param('id') postId: string, @Request() req: any) {
    await this.postsService.likePost(postId, req.user.id);
    return { message: 'Post liked successfully' };
  }

  @Delete(':id/like')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Unlike a post' })
  @ApiResponse({ status: 200, description: 'Post unliked' })
  async unlikePost(@Param('id') postId: string, @Request() req: any) {
    await this.postsService.unlikePost(postId, req.user.id);
    return { message: 'Post unliked successfully' };
  }

  @Get(':id/like-status')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Check if post is liked by current user' })
  @ApiResponse({ status: 200, description: 'Like status' })
  async getPostLikeStatus(@Param('id') postId: string, @Request() req: any) {
    const isLiked = await this.postsService.isPostLikedByUser(postId, req.user.id);
    return { isLiked };
  }
}

@ApiTags('comments')
@Controller('comments')
export class CommentsController {
  constructor(private readonly postsService: PostsService) {}

  @Post(':id/like')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Like a comment' })
  @ApiResponse({ status: 200, description: 'Comment liked' })
  async likeComment(@Param('id') commentId: string, @Request() req: any) {
    await this.postsService.likeComment(commentId, req.user.id);
    return { message: 'Comment liked successfully' };
  }

  @Delete(':id/like')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Unlike a comment' })
  @ApiResponse({ status: 200, description: 'Comment unliked' })
  async unlikeComment(@Param('id') commentId: string, @Request() req: any) {
    await this.postsService.unlikeComment(commentId, req.user.id);
    return { message: 'Comment unliked successfully' };
  }

  @Get(':id/like-status')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Check if comment is liked by current user' })
  @ApiResponse({ status: 200, description: 'Like status' })
  async getCommentLikeStatus(@Param('id') commentId: string, @Request() req: any) {
    const isLiked = await this.postsService.isCommentLikedByUser(commentId, req.user.id);
    return { isLiked };
  }
}