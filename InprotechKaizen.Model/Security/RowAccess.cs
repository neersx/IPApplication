using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Security
{
    [Table("ROWACCESS")]
    public class RowAccess
    {
        [Obsolete("For persistence only.")]
        public RowAccess()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public RowAccess(string name, string description)
        {
            Name = name;
            Description = description;
            Details = new Collection<RowAccessDetail>();
        }

        [Key]
        [MaxLength(30)]
        [Column("ACCESSNAME")]
        public string Name { get; set; }

        [MaxLength(254)]
        [Column("ACCESSDESC")]
        public string Description { get; set; }

        public virtual ICollection<RowAccessDetail> Details { get; set; }
    }

    public static class RowAccessType
    {
        public static readonly string Case = "C";
        public static readonly string Name = "N";
    }
}