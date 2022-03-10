using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Configuration
{
    [Table("RESOURCE")]
    public class Device
    {
        [Obsolete("For persistence only.")]
        public Device()
        {
        }

        public Device(int id, short type, string name)
        {
            if(string.IsNullOrEmpty(name)) throw new ArgumentException("A valid device description is required.");

            Id = id;
            Type = type;
            Name = name;
        }

        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Key]
        [Column("RESOURCENO")]
        public int Id { get; set; }

        [Column("TYPE")]
        public short Type { get; set; }

        [MaxLength(254)]
        [Column("DESCRIPTION")]
        public string Name { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? NameTId { get; set; }
    }
}
