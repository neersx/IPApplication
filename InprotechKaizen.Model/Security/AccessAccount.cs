using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Security
{
    [Table("ACCESSACCOUNT")]
    public class AccessAccount
    {
        [Obsolete("For persistence only.")]
        public AccessAccount()
        {
        }

        public AccessAccount(string name, bool isInternal = false)
        {
            if (name == null) throw new ArgumentNullException(nameof(name));

            Name = name;
            IsInternal = isInternal;
        }

        public AccessAccount(int id, string name, bool isInternal = false) : this(name, isInternal)
        {
            Id = id;
        }

        [Column("ACCOUNTID")]
        public int Id { get; protected set; }

        [Required]
        [MaxLength(50)]
        [Column("ACCOUNTNAME")]
        public string Name { get; protected set; }

        [Column("ISINTERNAL")]
        public bool IsInternal { get; protected set; }
    }
}