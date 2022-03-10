using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Cases
{
    [Table("IMAGE")]
    public class Image
    {
        [Obsolete("For persistence only.")]
        public @Image()
        {
        }

        public @Image(int id)
        {
            Id = id;
        }

        [Column("IMAGEID")]
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int Id { get; protected set; }

        [SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays")]
        [Column("IMAGEDATA")]
        public byte[] ImageData { get; set; }

        [ForeignKey("Id")]
        public virtual ImageDetail Detail { get; set; }
    }
}