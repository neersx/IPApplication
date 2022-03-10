namespace Inprotech.Web.BatchEventUpdate.Models
{
    public class ValidActionModel
    {
        public ValidActionModel(string id, string name)
        {
            ActionId = id;
            Name = name;
        }

        public string Name { get; private set; }

        public string ActionId { get; private set; }
    }
}