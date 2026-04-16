package handler

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	appdto "github.com/example/my-service/internal/app/application/dto"
	appservice "github.com/example/my-service/internal/app/application/service"
	domainrepo "github.com/example/my-service/internal/app/domain/repository"
	httpdto "github.com/example/my-service/internal/app/interface/http/dto"
)

// UserHandler 用户 HTTP 处理器
type UserHandler struct {
	appService *appservice.UserApplicationService
}

func NewUserHandler(appService *appservice.UserApplicationService) *UserHandler {
	return &UserHandler{appService: appService}
}

// Create 创建用户
func (h *UserHandler) Create(c *gin.Context) {
	var req httpdto.CreateUserHTTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, httpdto.NewErrorResponse(err))
		return
	}

	resp, err := h.appService.CreateUser(c.Request.Context(), appdto.CreateUserRequest{
		Email: req.Email,
		Name:  req.Name,
	})
	if err != nil {
		if errors.Is(err, domainrepo.ErrEmailAlreadyExists) {
			c.JSON(http.StatusConflict, httpdto.NewErrorResponse(err))
			return
		}
		c.JSON(http.StatusInternalServerError, httpdto.NewErrorResponse(err))
		return
	}

	c.JSON(http.StatusCreated, resp)
}

// Get 查询用户
func (h *UserHandler) Get(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的用户 ID"})
		return
	}

	resp, err := h.appService.GetUser(c.Request.Context(), id)
	if err != nil {
		if errors.Is(err, domainrepo.ErrUserNotFound) {
			c.JSON(http.StatusNotFound, httpdto.NewErrorResponse(err))
			return
		}
		c.JSON(http.StatusInternalServerError, httpdto.NewErrorResponse(err))
		return
	}

	c.JSON(http.StatusOK, resp)
}

// Update 更新用户
func (h *UserHandler) Update(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的用户 ID"})
		return
	}

	var req httpdto.UpdateUserHTTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, httpdto.NewErrorResponse(err))
		return
	}

	resp, err := h.appService.UpdateUser(c.Request.Context(), id, appdto.UpdateUserRequest{
		Email: req.Email,
		Name:  req.Name,
	})
	if err != nil {
		if errors.Is(err, domainrepo.ErrUserNotFound) {
			c.JSON(http.StatusNotFound, httpdto.NewErrorResponse(err))
			return
		}
		c.JSON(http.StatusInternalServerError, httpdto.NewErrorResponse(err))
		return
	}

	c.JSON(http.StatusOK, resp)
}

// List 用户列表
func (h *UserHandler) List(c *gin.Context) {
	var req httpdto.ListUsersHTTPRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, httpdto.NewErrorResponse(err))
		return
	}
	if req.Limit == 0 {
		req.Limit = 20
	}

	resp, err := h.appService.ListUsers(c.Request.Context(), req.Offset, req.Limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, httpdto.NewErrorResponse(err))
		return
	}

	c.JSON(http.StatusOK, resp)
}

// Delete 删除用户
func (h *UserHandler) Delete(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的用户 ID"})
		return
	}

	if err := h.appService.DeleteUser(c.Request.Context(), id); err != nil {
		if errors.Is(err, domainrepo.ErrUserNotFound) {
			c.JSON(http.StatusNotFound, httpdto.NewErrorResponse(err))
			return
		}
		c.JSON(http.StatusInternalServerError, httpdto.NewErrorResponse(err))
		return
	}

	c.JSON(http.StatusNoContent, nil)
}
