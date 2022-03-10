using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Inprotech.Integration.Storage
{
    [Table("MessageStoreFileQueue")]
    public class MessageStoreFileQueue
    {
        [Key]
        public long Id { get; set; }

        public string Path { get; set; }        
    }
}
