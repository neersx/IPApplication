using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Security
{
    [Table("USERIDENTITY")]
    public class User
    {
        [Obsolete("For persistence only.")]
        public User()
        {
        }

        public User(string userName, bool isExternalUser)
        {
            if (string.IsNullOrWhiteSpace(userName)) throw new ArgumentNullException(nameof(userName));

            UserName = userName;
            IsExternalUser = isExternalUser;
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public User(string userName, bool isExternalUser, Profile profile)
            : this(userName, isExternalUser)
        {
            Profile = profile;
        }

        [Key]
        [Column("IDENTITYID")]
        public int Id { get; protected set; }

        [MaxLength(254)]
        [Column("CPAGLOBALUSERID")]
        public string Guk { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("LOGINID")]
        public string UserName { get; protected set; }

        [SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays")]
        [Column("PASSWORD")]
        public byte[] PasswordMd5 { get; set; }

        [Column("ISEXTERNALUSER")]
        public bool IsExternalUser { get; protected set; }

        [Column("ISVALIDWORKBENCH")]
        public bool IsValid { get; set; }

        [Column("INVALIDLOGINS")]
        public int InvalidLogins { get; set; }

        [Column("ISLOCKED")]
        public bool IsLocked { get; set; }

        [Column("NAMENO")]
        public int NameId { get; set; }

        [Column("DEFAULTPORTALID")]
        public int? DefaultPortalId { get; set; }

        public virtual AccessAccount AccessAccount { get; set; }

        public virtual ICollection<Role> Roles { get; set; } = new Collection<Role>();

        public virtual Profile Profile { get; internal set; }

        public virtual ICollection<RowAccess> RowAccessPermissions { get; set; } = new Collection<RowAccess>();

        public virtual ICollection<License> Licences { get; set; } = new Collection<License>();

        [ForeignKey("NameId")]
        public virtual Name Name { get; set; }

        [MaxLength(32)]
        [Column("PasswordSalt")]
        public string PasswordSalt { get; set; }

        [SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays")]
        [Column("PasswordSha")]
        public byte[] PasswordSha { get; set; }

        [Column("PASSWORDHISTORY")]
        public string PasswordHistory { get; set; }
        
        [Column("PASSWORDUPDATEDDATE")]
        public DateTime? PasswordUpdatedDate { get; set; }

        [Column("WRITEDOWNLIMIT")]
        public decimal? WriteDownLimit { get; set; }
    }
}