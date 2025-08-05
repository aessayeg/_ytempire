/**
 * AuditLog Model - Sequelize model for system.audit_logs table
 * YTEmpire Project
 */

module.exports = (sequelize, DataTypes) => {
  const AuditLog = sequelize.define(
    'AuditLog',
    {
      log_id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
      },
      account_id: {
        type: DataTypes.UUID,
        references: {
          model: 'accounts',
          key: 'account_id',
        },
      },
      action_type: {
        type: DataTypes.STRING(100),
        allowNull: false,
      },
      resource_type: {
        type: DataTypes.STRING(100),
        allowNull: false,
      },
      resource_id: {
        type: DataTypes.UUID,
      },
      changes: {
        type: DataTypes.JSONB,
        defaultValue: {},
      },
      ip_address: {
        type: DataTypes.INET,
      },
      user_agent: {
        type: DataTypes.TEXT,
      },
      request_id: {
        type: DataTypes.UUID,
      },
      metadata: {
        type: DataTypes.JSONB,
        defaultValue: {},
      },
    },
    {
      tableName: 'audit_logs',
      schema: 'system',
      timestamps: true,
      updatedAt: false,
      underscored: true,
      indexes: [
        {
          fields: ['account_id'],
        },
        {
          fields: ['action_type'],
        },
        {
          fields: ['resource_type', 'resource_id'],
        },
        {
          fields: ['created_at'],
        },
      ],
    }
  );

  // Static methods
  AuditLog.logAction = async function (data) {
    return await this.create({
      account_id: data.accountId,
      action_type: data.actionType,
      resource_type: data.resourceType,
      resource_id: data.resourceId,
      changes: data.changes || {},
      ip_address: data.ipAddress,
      user_agent: data.userAgent,
      request_id: data.requestId,
      metadata: data.metadata || {},
    });
  };

  return AuditLog;
};
