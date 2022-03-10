using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names
{
    [Table("NAMETELECOM")]
    public class NameTelecom
    {
        [Obsolete("For persistence only")]
        public NameTelecom()
        {
            
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public NameTelecom(Name name, Telecommunication telecommunication)
        {
            if (name == null) throw new ArgumentNullException("name");
            if (telecommunication == null) throw new ArgumentNullException("telecommunication");

            NameId = name.Id;
            TeleCode = telecommunication.Id;
            Telecommunication = telecommunication;
        }

        [Key]
        [Column("NAMENO", Order = 1)]
        public int NameId { get; set; }

        [Key]
        [Column("TELECODE", Order = 2)]
        public int TeleCode { get; set; }

        [MaxLength(254)]
        [Column("TELECOMDESC")]
        public string TelecomDesc { get; set; }

        public virtual Telecommunication Telecommunication { get; protected set; }
    }
}