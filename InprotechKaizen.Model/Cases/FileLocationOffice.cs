using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Configuration;

namespace InprotechKaizen.Model.Cases
{
    [Table("FILELOCATIONOFFICE")]
    public class FileLocationOffice
    {
        public FileLocationOffice() {}

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public FileLocationOffice(TableCode fileLocation, Office office)
        {
            FileLocation = fileLocation;
            Office = office;
            FileLocationId = fileLocation.Id;
            OfficeId = office.Id;
        }

        public FileLocationOffice(int fileLocationId, int officeId)
        {
            FileLocationId = fileLocationId;
            OfficeId = officeId;
        }

        [Key]
        [Column("FILELOCATIONID", Order = 0)]
        public int FileLocationId { get; protected set; }

        [Key]
        [Column("OFFICEID", Order = 1)]
        public int OfficeId { get; protected set; }

        [ForeignKey("FileLocationId")]
        public virtual TableCode FileLocation { get; protected set; }

        [ForeignKey("OfficeId")]
        public virtual Office Office { get; protected set; }
    }
}
