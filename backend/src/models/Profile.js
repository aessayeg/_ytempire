/**
 * Profile Model - Sequelize model for users.profiles table
 * YTEmpire Project
 */

module.exports = (sequelize, DataTypes) => {
  const Profile = sequelize.define('Profile', {
    profile_id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    account_id: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'accounts',
        key: 'account_id'
      }
    },
    first_name: {
      type: DataTypes.STRING(100)
    },
    last_name: {
      type: DataTypes.STRING(100)
    },
    display_name: {
      type: DataTypes.STRING(150)
    },
    bio: {
      type: DataTypes.TEXT
    },
    avatar_url: {
      type: DataTypes.STRING(500)
    },
    timezone: {
      type: DataTypes.STRING(50),
      defaultValue: 'UTC'
    },
    language: {
      type: DataTypes.STRING(10),
      defaultValue: 'en'
    },
    company_name: {
      type: DataTypes.STRING(200)
    },
    website_url: {
      type: DataTypes.STRING(500)
    }
  }, {
    tableName: 'profiles',
    schema: 'users',
    timestamps: true,
    underscored: true
  });

  // Associations
  Profile.associate = (models) => {
    Profile.belongsTo(models.User, {
      foreignKey: 'account_id',
      as: 'account'
    });
  };

  return Profile;
};