import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Post } from './entities/post.entity';
import { Comment } from './entities/comment.entity';
import { Like } from './entities/like.entity';
import { Follow } from './entities/follow.entity';
import { PostsService } from './posts.service';
import { PostsController, CommentsController } from './posts.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([Post, Comment, Like, Follow]),
  ],
  controllers: [PostsController, CommentsController],
  providers: [PostsService],
  exports: [PostsService],
})
export class PostsModule {}