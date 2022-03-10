using System.Collections.Generic;
using Inprotech.Web.Picklists;

namespace Inprotech.Web.Configuration.RecordalType
{
    public class RecordalTypeItems
    {
        public int Id { get; set; }
        public string RecordalType { get; set; }
        public string RequestEvent { get; set; }
        public string RequestAction { get; set; }
        public string RecordalEvent { get; set; }
        public string RecordalAction { get; set; }
    }

    public class RecordalElementsModel
    {
        public int Id { get; set; }
        public DropDown Element { get; set; }
        public string ElementLabel { get; set; }
        public NameTypeModel NameType { get; set; }
        public string Attribute { get; set; }
    }

    public class DropDown
    {
        public int Key { get; set; }
        public string Value { get; set; }
    }

    public class RecordalTypeModel
    {
        public int Id { get; set; }
        public string RecordalType { get; set; }
        public IEnumerable<RecordalElementsModel> Elements { get; set; }
        public Action RequestAction { get; set; }
        public Event RequestEvent { get; set; }
        public Action RecordalAction { get; set; }
        public Event RecordalEvent { get; set; }
        public string Status { get; set; }
    }

    public class RecordalTypeRequest
    {
        public int Id { get; set; }
        public string RecordalType { get; set; }
        public IEnumerable<RecordalElementRequest> Elements { get; set; }
        public string RequestAction { get; set; }
        public int? RequestEvent { get; set; }
        public string RecordalAction { get; set; }
        public int? RecordalEvent { get; set; }
        public string Status { get; set; }
    }

    public class RecordalElementRequest
    {
        public int Id { get; set; }
        public int Element { get; set; }
        public string ElementLabel { get; set; }
        public string NameType { get; set; }
        public string Attribute { get; set; }
        public string Status { get; set; }
    }
}
