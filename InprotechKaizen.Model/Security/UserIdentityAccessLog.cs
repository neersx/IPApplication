using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Security
{
    [Table("USERIDENTITYACCESSLOG")]
    public class UserIdentityAccessLog
    {
        [Obsolete("For persistence only.")]
        public UserIdentityAccessLog()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "login")]
        public UserIdentityAccessLog(int identityId,string provider, string application, DateTime loginTime)
        {
            IdentityId = identityId;
            Provider = provider;
            LoginTime = loginTime;
            Application = application;
        }

        [Column("LOGID")]
        [Key]
        public long LogId { get; set; }

        [Column("IDENTITYID")]
        public int IdentityId { get; private set; }

        [Required]
        [MaxLength(30)]
        [Column("PROVIDER")]
        public string Provider { get; private set; }

        [MaxLength(100)]
        [Column("SOURCE")]
        public string Source { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Login")]
        [Column("LOGINTIME")]
        public DateTime LoginTime { get; protected set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Logout")]
        [Column("LOGOUTTIME")]
        public DateTime? LogoutTime { get; set; }

        [Column("LASTEXTENSION")]
        public DateTime? LastExtension { get; set; }

        [Column("TOTALEXTENSIONS")]
        public int? TotalExtensions { get; set; }

        [Column("DATA")]
        public string Data { get; set; }

        [MaxLength(128)]
        [Column("APPLICATION")]
        public string Application { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LastChanged { get; set; }
        
        [MaxLength(128)]
        [Column("LOGAPPLICATION")]
        public string LogApplication { get; set; }

        public virtual User User { get; set; }
    }
}
