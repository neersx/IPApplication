using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Security
{
    [Table("EXTERNALCREDENTIALS")]
    public class ExternalCredentials
    {
        [Obsolete("For persistance only.")]
        public ExternalCredentials()
        {
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public ExternalCredentials(User user, string userName, string password, string providerName)
        {
            if (user == null) throw new ArgumentNullException("user");
            if (userName == null) throw new ArgumentNullException("userName");
            if (password == null) throw new ArgumentNullException("password");
            if (providerName == null) throw new ArgumentNullException("providerName");

            User = user;
            UserName = userName;
            Password = password;
            ProviderName = providerName;
        }

        [Key]
        [Column("ID")]
        public int Id { get; protected set; }

        [Required]
        [MaxLength(30)]
        [Column("PROVIDERNAME")]
        public string ProviderName { get; set; }

        [Required]
        [MaxLength(100)]
        [Column("USERNAME")]
        public string UserName { get; set; }

        [Column("PASSWORD")]
        public string Password { get; set; }
        public virtual User User { get; set; }
    }
}