using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede.DataMapping
{
    [Table("DATAWIZARD")]
    public class DataWizard
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("WIZARDKEY")]
        public int WizardKey { get; set; }

        [Column("DEFAULTSOURCENO")]
        public int? DefaultSourceNo { get; set; }
    }
}
