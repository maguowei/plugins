package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"{{ .GoModule }}/{{ .Paths.Application }}/{{ .Aggregate.Name }}/dto"
	"{{ .GoModule }}/{{ .Paths.Application }}/{{ .Aggregate.Name }}/service"
	httpdto "{{ .GoModule }}/{{ .Paths.Interface }}/http/dto"
)

// {{ .Entity.Name }}Handler {{ .Entity.NameCN }}的 HTTP 处理器
type {{ .Entity.Name }}Handler struct {
	service *service.{{ .Entity.Name }}ApplicationService
}

// New{{ .Entity.Name }}Handler 创建 {{ .Entity.NameCN }}处理器
func New{{ .Entity.Name }}Handler(service *service.{{ .Entity.Name }}ApplicationService) *{{ .Entity.Name }}Handler {
	return &{{ .Entity.Name }}Handler{
		service: service,
	}
}

// Create{{ .Entity.Name }} 创建{{ .Entity.NameCN }}
// @Summary 创建{{ .Entity.NameCN }}
// @Description 创建新的{{ .Entity.NameCN }}
// @Tags {{ .Aggregate.Name }}
// @Accept json
// @Produce json
// @Param request body httpdto.Create{{ .Entity.Name }}Request true "创建{{ .Entity.NameCN }}请求"
// @Success 201 {object} httpdto.{{ .Entity.Name }}Response "{{ .Entity.NameCN }}创建成功"
// @Failure 400 {object} httpdto.ErrorResponse "请求参数错误"
// @Failure 500 {object} httpdto.ErrorResponse "服务器内部错误"
// @Router /{{ .Aggregate.NamePlural }}/ [post]
func (h *{{ .Entity.Name }}Handler) Create{{ .Entity.Name }}(c *gin.Context) {
	// 绑定请求参数
	var req httpdto.Create{{ .Entity.Name }}Request
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, httpdto.ErrorResponse{
			Error:   "invalid_request",
			Message: "请求参数格式错误: " + err.Error(),
		})
		return
	}

	// 转换为应用层 DTO
	createDTO := dto.Create{{ .Entity.Name }}DTO{
		{{- range .Entity.CreateFields }}
		{{ .Name }}: req.{{ .Name }},
		{{- end }}
	}

	// 调用应用层服务
	result, err := h.service.Create{{ .Entity.Name }}(c.Request.Context(), createDTO)
	if err != nil {
		// 根据错误类型返回不同的 HTTP 状态码
		c.JSON(http.StatusInternalServerError, httpdto.ErrorResponse{
			Error:   "create_failed",
			Message: "创建{{ .Entity.NameCN }}失败: " + err.Error(),
		})
		return
	}

	// 返回成功响应
	c.JSON(http.StatusCreated, httpdto.To{{ .Entity.Name }}Response(result))
}

// Get{{ .Entity.Name }} 获取{{ .Entity.NameCN }}详情
// @Summary 获取{{ .Entity.NameCN }}详情
// @Description 根据 ID 获取{{ .Entity.NameCN }}详情
// @Tags {{ .Aggregate.Name }}
// @Accept json
// @Produce json
// @Param id path string true "{{ .Entity.NameCN }} ID (UUID)"
// @Success 200 {object} httpdto.{{ .Entity.Name }}Response "{{ .Entity.NameCN }}详情"
// @Failure 400 {object} httpdto.ErrorResponse "请求参数错误"
// @Failure 404 {object} httpdto.ErrorResponse "{{ .Entity.NameCN }}不存在"
// @Failure 500 {object} httpdto.ErrorResponse "服务器内部错误"
// @Router /{{ .Aggregate.NamePlural }}/{id} [get]
func (h *{{ .Entity.Name }}Handler) Get{{ .Entity.Name }}(c *gin.Context) {
	// 解析 ID 参数
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, httpdto.ErrorResponse{
			Error:   "invalid_id",
			Message: "无效的{{ .Entity.NameCN }} ID 格式",
		})
		return
	}

	// 调用应用层服务
	result, err := h.service.Get{{ .Entity.Name }}(c.Request.Context(), id)
	if err != nil {
		// TODO: 区分不同的错误类型（如 NotFound）
		c.JSON(http.StatusNotFound, httpdto.ErrorResponse{
			Error:   "not_found",
			Message: "{{ .Entity.NameCN }}不存在",
		})
		return
	}

	// 返回成功响应
	c.JSON(http.StatusOK, httpdto.To{{ .Entity.Name }}Response(result))
}

// Update{{ .Entity.Name }} 更新{{ .Entity.NameCN }}
// @Summary 更新{{ .Entity.NameCN }}
// @Description 根据 ID 更新{{ .Entity.NameCN }}信息
// @Tags {{ .Aggregate.Name }}
// @Accept json
// @Produce json
// @Param id path string true "{{ .Entity.NameCN }} ID (UUID)"
// @Param request body httpdto.Update{{ .Entity.Name }}Request true "更新{{ .Entity.NameCN }}请求"
// @Success 200 {object} httpdto.{{ .Entity.Name }}Response "{{ .Entity.NameCN }}更新成功"
// @Failure 400 {object} httpdto.ErrorResponse "请求参数错误"
// @Failure 404 {object} httpdto.ErrorResponse "{{ .Entity.NameCN }}不存在"
// @Failure 500 {object} httpdto.ErrorResponse "服务器内部错误"
// @Router /{{ .Aggregate.NamePlural }}/{id} [put]
func (h *{{ .Entity.Name }}Handler) Update{{ .Entity.Name }}(c *gin.Context) {
	// 解析 ID 参数
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, httpdto.ErrorResponse{
			Error:   "invalid_id",
			Message: "无效的{{ .Entity.NameCN }} ID 格式",
		})
		return
	}

	// 绑定请求参数
	var req httpdto.Update{{ .Entity.Name }}Request
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, httpdto.ErrorResponse{
			Error:   "invalid_request",
			Message: "请求参数格式错误: " + err.Error(),
		})
		return
	}

	// 转换为应用层 DTO
	updateDTO := dto.Update{{ .Entity.Name }}DTO{
		ID: id,
		{{- range .Entity.UpdateFields }}
		{{ .Name }}: req.{{ .Name }},
		{{- end }}
	}

	// 调用应用层服务
	result, err := h.service.Update{{ .Entity.Name }}(c.Request.Context(), updateDTO)
	if err != nil {
		c.JSON(http.StatusInternalServerError, httpdto.ErrorResponse{
			Error:   "update_failed",
			Message: "更新{{ .Entity.NameCN }}失败: " + err.Error(),
		})
		return
	}

	// 返回成功响应
	c.JSON(http.StatusOK, httpdto.To{{ .Entity.Name }}Response(result))
}

// Delete{{ .Entity.Name }} 删除{{ .Entity.NameCN }}
// @Summary 删除{{ .Entity.NameCN }}
// @Description 根据 ID 删除{{ .Entity.NameCN }}
// @Tags {{ .Aggregate.Name }}
// @Accept json
// @Produce json
// @Param id path string true "{{ .Entity.NameCN }} ID (UUID)"
// @Success 204 "删除成功，无内容返回"
// @Failure 400 {object} httpdto.ErrorResponse "请求参数错误"
// @Failure 404 {object} httpdto.ErrorResponse "{{ .Entity.NameCN }}不存在"
// @Failure 500 {object} httpdto.ErrorResponse "服务器内部错误"
// @Router /{{ .Aggregate.NamePlural }}/{id} [delete]
func (h *{{ .Entity.Name }}Handler) Delete{{ .Entity.Name }}(c *gin.Context) {
	// 解析 ID 参数
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, httpdto.ErrorResponse{
			Error:   "invalid_id",
			Message: "无效的{{ .Entity.NameCN }} ID 格式",
		})
		return
	}

	// 调用应用层服务
	if err := h.service.Delete{{ .Entity.Name }}(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, httpdto.ErrorResponse{
			Error:   "delete_failed",
			Message: "删除{{ .Entity.NameCN }}失败: " + err.Error(),
		})
		return
	}

	// 返回成功响应（204 No Content）
	c.Status(http.StatusNoContent)
}

// List{{ .Entity.NamePlural }} 获取{{ .Entity.NameCN }}列表
// @Summary 获取{{ .Entity.NameCN }}列表
// @Description 获取{{ .Entity.NameCN }}列表，支持分页
// @Tags {{ .Aggregate.Name }}
// @Accept json
// @Produce json
// @Param page query int false "页码，默认 1" default(1)
// @Param page_size query int false "每页数量，默认 20" default(20)
// @Success 200 {object} httpdto.{{ .Entity.Name }}ListResponse "{{ .Entity.NameCN }}列表"
// @Failure 400 {object} httpdto.ErrorResponse "请求参数错误"
// @Failure 500 {object} httpdto.ErrorResponse "服务器内部错误"
// @Router /{{ .Aggregate.NamePlural }}/ [get]
func (h *{{ .Entity.Name }}Handler) List{{ .Entity.NamePlural }}(c *gin.Context) {
	// 解析分页参数
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	// 参数验证
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	// 调用应用层服务
	results, total, err := h.service.List{{ .Entity.NamePlural }}(c.Request.Context(), page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, httpdto.ErrorResponse{
			Error:   "list_failed",
			Message: "获取{{ .Entity.NameCN }}列表失败: " + err.Error(),
		})
		return
	}

	// 返回成功响应
	c.JSON(http.StatusOK, httpdto.To{{ .Entity.Name }}ListResponse(results, total, page, pageSize))
}
