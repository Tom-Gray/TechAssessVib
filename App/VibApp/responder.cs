using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;

namespace VibApp
{
    public class Responder : Controller
    {
        [HttpGet]
        [Route("/")]
        public IActionResult Get()
        {
            //create connection string 
            string connectionString = "server=localhost\\SQLEXPRESS;Trusted_Connection=yes;database=Data;connection timeout=30";
            //The Using keyword means we'll automatically drop the sql connection after the Return.
            using (var connection = new SqlConnection(connectionString))
            {
                if (connection.State != System.Data.ConnectionState.Open)
                    connection.Open();
                //build the query string
                const string query = "select * from data where id = '1'";
                //build the command to execute
                var command = new SqlCommand(query, connection);
                //return the result as a string to the caller.
                return Content(command.ExecuteScalar().ToString());
            }
        }
    }
}
