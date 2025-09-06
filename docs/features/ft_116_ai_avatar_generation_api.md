# FT-116 AI Avatar Generation API Service

**Feature ID**: FT-116  
**Priority**: High  
**Category**: AI/API/Infrastructure  
**Effort Estimate**: 6-8 hours  
**Dependencies**: OpenAI GPT-Image-1 API access, Firebase project  
**Status**: Specification  
**Goal**: Create a configurable AI avatar generation API service that accepts prompt + image inputs and returns generated avatar images

## Overview

Implement a generic AI Avatar Generation API service using GPT-Image-1 that accepts text prompts and user photos as inputs to generate personalized avatars. The service is narrative-agnostic and configurable through prompt templates and service parameters, enabling various avatar generation use cases through configuration rather than code changes.

## Core API Specification

### **Input/Output Contract**
```
Input:  Text Prompt + User Photo + Configuration Parameters
Output: Generated Avatar Image URL + Metadata
```

### **Service Boundaries**
- **Handles**: Image generation, prompt processing, quality management, error handling
- **Does NOT Handle**: Business logic, narrative concepts, user management, UI/UX
- **Configurable**: Style prompts, quality settings, safety parameters, caching rules

## Functional Requirements

### Core API Functionality
- **FR-116-01**: Accept text prompt and image as primary inputs
- **FR-116-02**: Support configurable prompt templates and style parameters
- **FR-116-03**: Generate avatar using GPT-Image-1 multimodal capabilities
- **FR-116-04**: Return generated image URL with generation metadata
- **FR-116-05**: Handle multiple quality levels (low, medium, high) based on configuration

### Configuration Management
- **FR-116-06**: Support configurable prompt templates via JSON configuration
- **FR-116-07**: Enable style parameter customization (quality, moderation, etc.)
- **FR-116-08**: Allow cost management through quality and usage controls
- **FR-116-09**: Support multiple generation providers (GPT-Image-1 primary, extensible)
- **FR-116-10**: Configure safety and content moderation parameters

### API Management
- **FR-116-11**: Implement rate limiting and usage tracking
- **FR-116-12**: Provide comprehensive error handling and status reporting
- **FR-116-13**: Support async generation with job status tracking
- **FR-116-14**: Cache generated images with configurable TTL
- **FR-116-15**: Log generation events for monitoring and analytics

## Technical API Specification

### **REST API Endpoints**

#### **Generate Avatar**
```http
POST /api/v1/avatar/generate
Content-Type: application/json

{
  "prompt": "string",              // Base generation prompt
  "image": "string",               // Base64 encoded image or image URL
  "style_config": "string",        // Style configuration key (optional)
  "quality": "medium",             // low|medium|high (optional, defaults to config)
  "async": false,                  // Generate synchronously or async (optional)
  "user_id": "string",             // For usage tracking (optional)
  "metadata": {                    // Additional context (optional)
    "session_id": "string",
    "app_version": "string"
  }
}
```

**Response (Sync)**:
```json
{
  "status": "success",
  "avatar_id": "uuid",
  "image_url": "https://...",
  "generation_time_ms": 1234,
  "quality_used": "medium",
  "cost_estimate": 0.07,
  "metadata": {
    "provider": "gpt-image-1",
    "model_version": "1.0",
    "cached": false
  }
}
```

**Response (Async)**:
```json
{
  "status": "accepted",
  "job_id": "uuid",
  "estimated_completion_seconds": 30,
  "status_url": "/api/v1/avatar/status/{job_id}"
}
```

#### **Check Generation Status**
```http
GET /api/v1/avatar/status/{job_id}
```

**Response**:
```json
{
  "status": "completed|processing|failed",
  "avatar_id": "uuid",
  "image_url": "https://...",
  "progress_percent": 100,
  "error_message": null
}
```

#### **Configuration Management**
```http
GET /api/v1/avatar/config
POST /api/v1/avatar/config
```

### **Configuration Schema**

#### **Service Configuration**
```json
{
  "service_config": {
    "default_quality": "medium",
    "max_concurrent_generations": 10,
    "default_timeout_seconds": 45,
    "enable_caching": true,
    "cache_ttl_hours": 24,
    "cost_limits": {
      "daily_budget": 50.0,
      "per_user_daily_limit": 5
    }
  },
  "provider_config": {
    "gpt_image_1": {
      "api_key": "${OPENAI_API_KEY}",
      "model": "gpt-image-1",
      "max_retries": 3,
      "timeout_seconds": 30,
      "quality_settings": {
        "low": { "quality": "low", "cost": 0.02 },
        "medium": { "quality": "medium", "cost": 0.07 },
        "high": { "quality": "high", "cost": 0.19 }
      },
      "safety_settings": {
        "moderation": "auto",
        "content_filter": "strict"
      }
    }
  },
  "style_templates": {
    "cartoon_3d": {
      "base_prompt": "3D cartoon character in Pixar animation style, warm orange lighting, cozy workspace environment, large expressive eyes, genuine expression",
      "transformation_instruction": "Transform this person into a 3D cartoon character while maintaining their facial features and identity",
      "quality_modifiers": {
        "low": "simple rendering",
        "medium": "professional 3D animation quality",
        "high": "high-detail Pixar-level rendering"
      }
    },
    "professional": {
      "base_prompt": "Professional headshot style, clean background, confident expression, business attire",
      "transformation_instruction": "Create a professional avatar maintaining the person's identity",
      "quality_modifiers": {
        "low": "standard quality",
        "medium": "professional photography quality",
        "high": "studio portrait quality"
      }
    },
    "artistic": {
      "base_prompt": "Artistic portrait style, creative lighting, expressive and unique",
      "transformation_instruction": "Transform into an artistic avatar while preserving identity",
      "quality_modifiers": {
        "low": "sketch style",
        "medium": "digital art quality",
        "high": "masterpiece artistic rendering"
      }
    }
  }
}
```

## Implementation Architecture

### **FastAPI Service Structure**
```python
# main.py
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, Dict, Any
import uuid
from datetime import datetime

app = FastAPI(title="AI Avatar Generation API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class AvatarGenerationRequest(BaseModel):
    prompt: str
    image: str  # Base64 or URL
    style_config: Optional[str] = "default"
    quality: Optional[str] = None  # Uses config default if not specified
    async_generation: Optional[bool] = False
    user_id: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = {}

class AvatarGenerationResponse(BaseModel):
    status: str
    avatar_id: str
    image_url: Optional[str] = None
    job_id: Optional[str] = None
    generation_time_ms: Optional[int] = None
    quality_used: Optional[str] = None
    cost_estimate: Optional[float] = None
    metadata: Optional[Dict[str, Any]] = {}

@app.post("/api/v1/avatar/generate", response_model=AvatarGenerationResponse)
async def generate_avatar(
    request: AvatarGenerationRequest,
    background_tasks: BackgroundTasks
):
    try:
        # Load configuration
        config = await ConfigManager.get_config()
        
        # Validate request
        validation_result = await RequestValidator.validate(request, config)
        if not validation_result.is_valid:
            raise HTTPException(status_code=400, detail=validation_result.error)
        
        # Check rate limits and budget
        usage_check = await UsageManager.check_limits(request.user_id, config)
        if not usage_check.allowed:
            raise HTTPException(status_code=429, detail=usage_check.reason)
        
        if request.async_generation:
            # Async generation
            job_id = str(uuid.uuid4())
            background_tasks.add_task(
                GenerationManager.process_async_generation,
                job_id, request, config
            )
            return AvatarGenerationResponse(
                status="accepted",
                avatar_id="",
                job_id=job_id
            )
        else:
            # Sync generation
            result = await GenerationManager.generate_avatar(request, config)
            return AvatarGenerationResponse(
                status="success",
                avatar_id=result.avatar_id,
                image_url=result.image_url,
                generation_time_ms=result.generation_time_ms,
                quality_used=result.quality_used,
                cost_estimate=result.cost_estimate,
                metadata=result.metadata
            )
            
    except Exception as e:
        # Log error and return standardized error response
        await ErrorLogger.log_generation_error(e, request)
        raise HTTPException(status_code=500, detail="Avatar generation failed")

@app.get("/api/v1/avatar/status/{job_id}")
async def get_generation_status(job_id: str):
    status = await JobManager.get_job_status(job_id)
    if not status:
        raise HTTPException(status_code=404, detail="Job not found")
    return status

@app.get("/api/v1/avatar/config")
async def get_configuration():
    config = await ConfigManager.get_public_config()
    return config

@app.post("/api/v1/avatar/config")
async def update_configuration(config: Dict[str, Any]):
    # Admin endpoint for configuration updates
    result = await ConfigManager.update_config(config)
    return {"status": "updated", "validation_errors": result.errors}
```

### **Core Service Classes**

#### **Generation Manager**
```python
# services/generation_manager.py
from typing import Dict, Any
import aiohttp
import base64
from .gpt_image_service import GPTImageService
from .prompt_builder import PromptBuilder
from .storage_service import StorageService

class GenerationManager:
    @staticmethod
    async def generate_avatar(request: AvatarGenerationRequest, config: Dict[str, Any]):
        start_time = datetime.now()
        
        try:
            # Build final prompt using template and user input
            prompt_builder = PromptBuilder(config)
            final_prompt = await prompt_builder.build_prompt(
                user_prompt=request.prompt,
                style_config=request.style_config,
                quality=request.quality or config['service_config']['default_quality']
            )
            
            # Generate avatar using configured provider
            provider = GPTImageService(config['provider_config']['gpt_image_1'])
            generation_result = await provider.generate_avatar(
                prompt=final_prompt,
                image=request.image,
                quality=request.quality or config['service_config']['default_quality']
            )
            
            # Store the generated image
            storage = StorageService(config)
            stored_url = await storage.store_avatar(
                generation_result.image_url,
                user_id=request.user_id
            )
            
            # Calculate generation time and cost
            generation_time = (datetime.now() - start_time).total_seconds() * 1000
            
            # Track usage
            await UsageManager.track_generation(
                user_id=request.user_id,
                cost=generation_result.cost,
                quality=generation_result.quality_used
            )
            
            return GenerationResult(
                avatar_id=str(uuid.uuid4()),
                image_url=stored_url,
                generation_time_ms=int(generation_time),
                quality_used=generation_result.quality_used,
                cost_estimate=generation_result.cost,
                metadata={
                    "provider": "gpt-image-1",
                    "model_version": generation_result.model_version,
                    "cached": False,
                    "style_config": request.style_config
                }
            )
            
        except Exception as e:
            await ErrorLogger.log_generation_error(e, request)
            raise
```

#### **Prompt Builder**
```python
# services/prompt_builder.py
class PromptBuilder:
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.style_templates = config.get('style_templates', {})
    
    async def build_prompt(
        self, 
        user_prompt: str, 
        style_config: str = "default",
        quality: str = "medium"
    ) -> str:
        # Get style template
        template = self.style_templates.get(style_config, {})
        base_prompt = template.get('base_prompt', '')
        transformation = template.get('transformation_instruction', '')
        quality_modifier = template.get('quality_modifiers', {}).get(quality, '')
        
        # Build final prompt
        final_prompt = f"""
        {transformation}
        
        Style Requirements:
        {base_prompt}
        {quality_modifier}
        
        User Context:
        {user_prompt}
        
        CRITICAL: Maintain the person's facial features and identity from the input photo
        while applying the specified style transformation.
        """
        
        return final_prompt.strip()
```

#### **GPT Image Service**
```python
# services/gpt_image_service.py
import openai
import base64
import requests
from typing import Optional

class GPTImageService:
    def __init__(self, provider_config: Dict[str, Any]):
        self.config = provider_config
        self.client = openai.OpenAI(api_key=provider_config['api_key'])
    
    async def generate_avatar(
        self, 
        prompt: str, 
        image: str, 
        quality: str = "medium"
    ) -> GenerationResult:
        try:
            # Prepare image input
            if image.startswith('http'):
                image_data = requests.get(image).content
                image_base64 = base64.b64encode(image_data).decode()
            elif image.startswith('data:image'):
                # Handle data URI
                image_base64 = image.split(',')[1]
            else:
                # Assume it's already base64
                image_base64 = image
            
            # Get quality settings
            quality_settings = self.config['quality_settings'][quality]
            
            # Generate with GPT-Image-1
            response = self.client.images.generate(
                model=self.config['model'],
                inputs=[
                    {"type": "image", "image": image_base64},
                    {"type": "text", "text": prompt}
                ],
                quality=quality_settings['quality'],
                size="1024x1024",
                n=1,
            )
            
            return GenerationResult(
                image_url=response.data[0].url,
                cost=quality_settings['cost'],
                quality_used=quality,
                model_version=self.config['model'],
                provider="gpt-image-1"
            )
            
        except Exception as e:
            await ErrorLogger.log_provider_error("gpt-image-1", e, prompt)
            raise
```

### **Configuration Management**
```python
# services/config_manager.py
import json
import os
from typing import Dict, Any

class ConfigManager:
    _config_cache = None
    _cache_timestamp = None
    
    @classmethod
    async def get_config(cls) -> Dict[str, Any]:
        # Load from file, environment, or database
        if cls._config_cache is None or cls._needs_refresh():
            cls._config_cache = await cls._load_config()
            cls._cache_timestamp = datetime.now()
        
        return cls._config_cache
    
    @classmethod
    async def _load_config(cls) -> Dict[str, Any]:
        # Priority: Environment variables > Config file > Defaults
        config_path = os.getenv('AVATAR_CONFIG_PATH', 'config/avatar_config.json')
        
        try:
            with open(config_path, 'r') as f:
                config = json.load(f)
        except FileNotFoundError:
            config = cls._get_default_config()
        
        # Override with environment variables
        config = cls._apply_env_overrides(config)
        
        return config
    
    @classmethod
    def _get_default_config(cls) -> Dict[str, Any]:
        return {
            "service_config": {
                "default_quality": "medium",
                "max_concurrent_generations": 5,
                "default_timeout_seconds": 45,
                "enable_caching": True,
                "cache_ttl_hours": 24
            },
            "provider_config": {
                "gpt_image_1": {
                    "model": "gpt-image-1",
                    "max_retries": 3,
                    "timeout_seconds": 30,
                    "quality_settings": {
                        "low": {"quality": "low", "cost": 0.02},
                        "medium": {"quality": "medium", "cost": 0.07},
                        "high": {"quality": "high", "cost": 0.19}
                    }
                }
            },
            "style_templates": {
                "default": {
                    "base_prompt": "Professional avatar with clean rendering",
                    "transformation_instruction": "Transform this person while maintaining their identity"
                }
            }
        }
```

## Usage Examples

### **Basic Avatar Generation**
```python
# Client usage example
import requests

response = requests.post('http://localhost:8000/api/v1/avatar/generate', json={
    "prompt": "Software developer, focused and analytical, modern workspace",
    "image": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQ...",
    "style_config": "cartoon_3d",
    "quality": "medium",
    "user_id": "user123"
})

result = response.json()
print(f"Generated avatar: {result['image_url']}")
```

### **Configuration Update**
```python
# Update style templates
new_config = {
    "style_templates": {
        "cyberpunk": {
            "base_prompt": "Cyberpunk style avatar with neon lighting and futuristic elements",
            "transformation_instruction": "Transform into cyberpunk character maintaining identity",
            "quality_modifiers": {
                "low": "simple neon effects",
                "medium": "detailed cyberpunk styling",
                "high": "cinematic cyberpunk quality"
            }
        }
    }
}

response = requests.post('http://localhost:8000/api/v1/avatar/config', json=new_config)
```

## Deployment Configuration

### **Environment Variables**
```env
# API Configuration
OPENAI_API_KEY=sk-...
AVATAR_CONFIG_PATH=/app/config/avatar_config.json
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_STORAGE_BUCKET=your-bucket.appspot.com

# Service Limits
MAX_DAILY_GENERATIONS=1000
MAX_USER_DAILY_GENERATIONS=10
DEFAULT_QUALITY=medium

# Monitoring
LOG_LEVEL=INFO
METRICS_ENABLED=true
```

### **Docker Deployment**
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### **Firebase Functions Deployment**
```yaml
# firebase.json
{
  "functions": {
    "source": ".",
    "runtime": "python311"
  }
}
```

## Testing Strategy

### **Unit Tests**
- Prompt building logic
- Configuration loading and validation
- Provider integration (with mocks)
- Error handling scenarios

### **Integration Tests**
- End-to-end avatar generation flow
- Configuration management
- Rate limiting and usage tracking
- Storage and caching functionality

### **Load Testing**
- Concurrent generation requests
- Rate limiting effectiveness
- Memory usage under load
- Response time benchmarks

## Success Metrics

### **Technical Performance**
- **Generation Success Rate**: >95% successful generations
- **Response Time**: <45 seconds for 90% of requests
- **Cost Efficiency**: Within configured budget limits
- **Uptime**: >99.5% service availability

### **Configuration Flexibility**
- **Style Templates**: Support 10+ configurable styles
- **Quality Levels**: 3+ quality/cost tiers working correctly
- **Provider Support**: Extensible architecture for multiple AI providers
- **Admin Configuration**: Real-time config updates without restart

## Acceptance Criteria

### **Core API Functionality**
- [ ] Generate avatar from prompt + image inputs successfully
- [ ] Support configurable quality levels (low, medium, high)
- [ ] Return generated image URL with metadata
- [ ] Handle sync and async generation modes
- [ ] Implement proper error handling and status codes

### **Configuration Management**
- [ ] Load configuration from JSON files and environment variables
- [ ] Support style template configuration without code changes
- [ ] Enable quality and cost parameter configuration
- [ ] Allow real-time configuration updates via API

### **Production Readiness**
- [ ] Implement rate limiting and usage tracking
- [ ] Support multiple deployment environments (local, Firebase Functions)
- [ ] Provide comprehensive logging and monitoring
- [ ] Handle provider failures gracefully with retry logic

### **Integration Support**
- [ ] Easy integration with Flutter/Dart applications
- [ ] RESTful API following standard conventions
- [ ] Clear documentation and usage examples
- [ ] Extensible architecture for future enhancements

## Definition of Done

The API service is complete when:
1. All core endpoints (generate, status, config) are implemented and tested
2. GPT-Image-1 integration generates high-quality avatars from prompt + image inputs
3. Configuration system supports style templates and service parameters
4. Rate limiting, usage tracking, and cost management are operational
5. Service can be deployed to Firebase Functions and run locally
6. Integration testing validates end-to-end functionality
7. Documentation includes API specification and usage examples
8. Error handling provides meaningful feedback for all failure scenarios

## Notes

This API service provides a narrative-agnostic foundation for AI avatar generation that can support multiple use cases through configuration. The separation of business logic from generation logic enables:

- **Mirror Realm avatars** through style template configuration
- **Professional headshots** through different prompt templates  
- **Artistic avatars** through creative style configurations
- **Future concepts** through new template additions

The configurable architecture ensures the service remains flexible and maintainable while providing a stable API contract for client applications.
