using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Inprotech.Integration.BulkCaseUpdates
{
    [Table("BulkCaseUpdatesSchedule")]
    public class BulkCaseUpdatesSchedule
    {
        [Key]
        public long Id { get; set; }

        public string JobArguments { get; set; }
    }
}
