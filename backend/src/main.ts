import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import helmet from 'helmet';
import * as compression from 'compression';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  const configService = app.get(ConfigService);
  const port = configService.get('PORT') || 3000;
  const apiPrefix = configService.get('API_PREFIX') || 'api/v1';

  // Security middleware
  app.use(helmet());
  app.use(compression());

  // CORS configuration
  app.enableCors({
    origin: [
      configService.get('FRONTEND_URL'),
      'http://localhost:3000',
      'http://localhost:3001',
      // iOS app will connect directly
      'capacitor://localhost',
      'ionic://localhost',
    ],
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  });

  // Global validation
  app.useGlobalPipes(
    new ValidationPipe({
      transform: true,
      whitelist: true,
      forbidNonWhitelisted: true,
    }),
  );

  // API prefix
  app.setGlobalPrefix(apiPrefix);

  // Swagger documentation
  if (configService.get('NODE_ENV') !== 'production') {
    const config = new DocumentBuilder()
      .setTitle('RepAlign API')
      .setDescription('Backend API for RepAlign - Civic engagement platform')
      .setVersion('1.0')
      .addBearerAuth()
      .addTag('auth', 'Authentication endpoints')
      .addTag('users', 'User management')
      .addTag('posts', 'Social posts and interactions')
      .addTag('congress', 'Congress data and legislators')
      .addTag('gamification', 'Points, badges, and leaderboards')
      .build();

    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('docs', app, document);
  }

  await app.listen(port);
  console.log(`🚀 RepAlign API is running on: http://localhost:${port}/${apiPrefix}`);
  console.log(`📖 Swagger docs available at: http://localhost:${port}/docs`);
}

bootstrap();