jQuery(document).ready(function($){

	// Installer 
	if ($("#install_or_upgrade").length) {
		$("body").on("click", '.installer_changeDisplayStateDivs', function(event) {
			changeDisplayState($(this).attr("data-target"), $(this).attr("data-state"));
		});
	
		$("#install_or_upgrade_form").validate({
			rules: {
				current_dada_files_parent_location: { 
					required: true
				}
			}
		});
	}
	if ($("#installer_configure_dada_mail").length) {
			
		$("body").on("click", '.radiochangeDisplayState', function(event) {
			changeDisplayState($(this).attr("data-target"), $(this).attr("data-state"));
		});

		$("body").on("click", '.test_sql_connection', function(event) {
			installer_test_sql_connection();
		});
		$("body").on("click", '.test_bounce_handler_pop3_connection', function(event) {
			installer_test_pop3_connection();
		});
		$("body").on("click", '.test_user_template', function(event) {
			test_user_template();
		});
				
		$("body").on("click", '.template_options_mode', function(event) {
			installer_toggle_template_mode_magic_options();
		});

/*
		$("body").on("click", '.bounce_handler_Connection_Protocol', function(event) {
			installer_toggle_bounce_handler_Connection_Protocol_options();
		});
*/			
		$("body").on("click", '.test_CAPTCHA_configuration', function(event) {
			test_CAPTCHA_configuration();
		});
		
		$("body").on("click", '.test_amazon_ses_configuration', function(event) {
			test_amazon_ses_configuration();
		});
		$.validator.addMethod("alphanumericunderscore", function(value, element) {
	    return this.optional(element) || value == value.match(/^[-a-zA-Z0-9_]+$/);
	    }, "Only letters, Numbers and Underscores Allowed.");
		$.validator.addMethod("alphanumeric", function(value, element) {
	    return this.optional(element) || value == value.match(/^[-a-zA-Z0-9]+$/);
	    }, "Only letters and Numbers Allowed.");

/*
	template_options_USER_TEMPLATE: {
		required: "#configure_user_template:checked"
	},
*/
		
		$("#installform").validate({
			rules: {
				program_url: { 
					required: true,
					url: true	
				}, 
				support_files_dir_path: { 
					required: true,					
				},
				support_files_dir_url: { 
						required: true,
						url: true	
				},
				dada_root_pass: {
					required: true,
					minlength: 8
				},
				dada_root_pass_again: {
					required: true,
					minlength: 8,
					equalTo: "#dada_root_pass"
				},
				bounce_handler_address: {
					required: false,
					email: true
				},
				security_ADMIN_FLAVOR_NAME: { 
					required: false, 
					alphanumericunderscore: true
				},
				security_SIGN_IN_FLAVOR_NAME: { 
					required: false, 
					alphanumericunderscore: true
				},
				amazon_ses_AWSAccessKeyId: { 
					required: false, 
				},
				amazon_ses_AWSSecretKey: { 
					required: false, 
				},
				scheduled_jobs_flavor: {
					required: false, 
					alphanumericunderscore: true
				}
			}, 
			messages: {
				dada_root_pass: {
					required: "Please provide a Root Password",
					minlength: "Your password must be at least 8 characters long"
				},
				dada_root_pass_again: {
					required: "Please provide a Root Password",
					minlength: "Your password must be at least 8 characters long",
					equalTo: "Please enter the same Root Password as above"
				}
			}					
		});


		$("body").on('click', "#install_wysiwyg_editors", function(event) {
			installer_checkbox_toggle_option_groups('install_wysiwyg_editors', 'install_wysiwyg_editors_options');
		});

		var o = [
			"s_program_url", 
			"program_name", 
			"amazon_ses", 
			"pii",
			"scheduled_jobs", 
			"deployment",
			"perl_env",
			"profiles",
			"templates", 
			"cache",
			"www_engine",
			"mime_tools",
			"debugging", 
			"google_maps",
			"security", 
			"global_api",
			"captcha", 
			"global_mailing_list", 
			"mass_mailing", 
			"confirmation_token", 
		];
		$.each(o, function(index, value) {			
			$("body").on('click', "#configure_" + value, function(event) {
				installer_checkbox_toggle_option_groups('configure_' + value, value +'_options');			
			});
			installer_checkbox_toggle_option_groups('configure_' + value, value +'_options');		
		}); 
		var oo = [
		"bridge", 
		"bounce_handler", 
		"wysiwyg_editors", 
		];
		$.each(oo, function(index, value) {
			$("body").on('click', "#install_" + value, function(event) {
				installer_checkbox_toggle_option_groups('install_' + value, value +'_options');			
			});
			installer_checkbox_toggle_option_groups('install_' + value, value +'_options');		
		}); 
		
		installer_dada_root_pass_options();


		//$("body").on('click', "#global_api_enable", function(event) {
		//	installer_checkbox_toggle_option_groups('global_api_enable', 'global_api_keys'); 
		//});
		//installer_checkbox_toggle_option_groups('global_api_enable', 'global_api_keys'); 
		
		$("body").on("click", '.reset_global_api_keys', function(event) {
			installer_set_up_global_api_options();
		});
		
		
		
		
		installer_toggle_dada_files_dirOptions();
		installer_toggle_captcha_type_options();
		installer_toggle_template_mode_magic_options();
		//installer_toggle_bounce_handler_Connection_Protocol_options();

		var hiding = [
			"dada_files_help", 
			"program_url_help", 
			"root_pass_help", 
			"support_files_help", 
			"backend_help", 
			"plugins_extensions_help", 
			"bounce_handler_configuration_help", 
			"additional_bounce_handler_configuration",
			"additional_bridge_configuration",
			"wysiwyg_editor_help",
			"test_sql_connection_results",
			"test_bounce_handler_pop3_connection_results",
			"test_user_template_results",
			"test_CAPTCHA_configuration_results",
			"test_amazon_ses_configuration_results",
       ];
		$.each(hiding, function(index, value) {
			$("#" + value).hide(); 
		}); 
		if ($("#install_type").val() != "upgrade"){ 
			$("#advanced_options").hide(); 
		}
		
		
		if ($("#install_type").val() == "upgrade"){ 
			
			installer_test_sql_connection();
			
			if ($("#install_bounce_handler").prop("checked") === true){ 
				installer_test_pop3_connection();
			}
			if ($("#configure_captcha").prop("checked") === true){ 
				if ($("#captcha_params_recaptcha_type_v2").prop("checked") === true){ 
					test_CAPTCHA_configuration();
				}	
			}
			if ($("#configure_amazon_ses").prop("checked") === true){ 
				test_amazon_ses_configuration(); 
			}
		}
		
		

	}
	if ($("#installer_install_dada_mail").length) {		
		$("body").on("click", '#move_installer_dir', function(event) {
			event.preventDefault();
			installer_move_installer_dir($(this).attr("data-chmod"));
		});
	}



function installer_test_sql_connection() {
	var target_div = 'test_sql_connection_results';
	$("#" + target_div).html('<p class="label info">Loading...</p>');
	if ($("#" + target_div).is(':hidden')) {
		$("#" + target_div).show();
	}

	var request = $.ajax({
		url: $("#self_url").val(),
		type: "POST",
		cache: false,
		data: {
			flavor: 'cgi_test_sql_connection',
			backend: $("#backend").val(),
			sql_server: $("#sql_server").val(),
			sql_port: $("#sql_port").val(),
			sql_database: $("#sql_database").val(),
			sql_username: $("#sql_username").val(),
			sql_password: $("#sql_password").val()
		},
		dataType: "html"
	});
	request.done(function(content) {
		//$("#" + target_div).hide('fade');
		$("#" + target_div).html(content);
		//$("#" + target_div).show('fade');
	});

}

function installer_test_pop3_connection() {
	var target_div = 'test_bounce_handler_pop3_connection_results';
	$("#" + target_div).html('<p class="label info">Loading...</p>');
	if ($("#" + target_div).is(':hidden')) {
		$("#" + target_div).show();
	}

	var bounce_handler_USESSL = 0; 
	if($("#bounce_handler_USESSL").prop("checked") === true){ 
		bounce_handler_USESSL = 1; 
	}
		
	var bounce_handler_starttls = 0; 
	if($("#bounce_handler_starttls").prop("checked") === true){ 
		bounce_handler_starttls = 1; 
	}
	
		
	var bounce_handler_SSL_verify_mode = 0; 
	if($("#bounce_handler_SSL_verify_mode").prop("checked") === true){ 
		bounce_handler_SSL_verify_mode = 1; 
	}
	
	bounce_handler_Connection_Protocol = 'POP3';
	if($("#bounce_handler_Connection_Protocol_POP3").prop("checked") === true){ 
		bounce_handler_Connection_Protocol = 'POP3'; 
	}
	if($("#bounce_handler_Connection_Protocol_IMAP").prop("checked") === true){ 
		bounce_handler_Connection_Protocol = 'IMAP'; 
	}
	
	
	var request = $.ajax({
		url: $("#self_url").val(),
		type: "POST",
		cache: false,
		data: {
			flavor: 'cgi_test_pop3_connection',
			bounce_handler_Connection_Protocol: bounce_handler_Connection_Protocol,
			bounce_handler_Server:          $("#bounce_handler_Server").val(),
			bounce_handler_Username:        $("#bounce_handler_Username").val(),
			bounce_handler_Password:        $("#bounce_handler_Password").val(),
			bounce_handler_USESSL:          bounce_handler_USESSL,
			bounce_handler_SSL_verify_mode: bounce_handler_SSL_verify_mode, 
			bounce_handler_starttls:        bounce_handler_starttls, 
			bounce_handler_AUTH_MODE:       $("#bounce_handler_AUTH_MODE").val(),
			bounce_handler_Port:            $("#bounce_handler_Port").val(),

		},
		dataType: "html"
	});
	request.done(function(content) {
		//$("#" + target_div).hide('fade');
		$("#" + target_div).html(content);
		//$("#" + target_div).show('fade');
	});
}

function test_amazon_ses_configuration() {
	var target_div = 'test_amazon_ses_configuration_results';
	$("#" + target_div).html('<p class="label info">Loading...</p>');
	if ($("#" + target_div).is(':hidden')) {
		$("#" + target_div).show();
	}
	
	var amazon_ses_Allowed_Sending_Quota_Percentage = $("#amazon_ses_Allowed_Sending_Quota_Percentage option:selected").val();
	var request = $.ajax({
		url: $("#self_url").val(),
		type: "POST",
		cache: false,
		data: {
			flavor:                                      'cgi_test_amazon_ses_configuration',
			amazon_ses_AWS_endpoint:                     $("#amazon_ses_AWS_endpoint").val(), 
			amazon_ses_AWSSecretKey:                     $("#amazon_ses_AWSSecretKey").val(),
			amazon_ses_AWSAccessKeyId:                   $("#amazon_ses_AWSAccessKeyId").val(),
			amazon_ses_Allowed_Sending_Quota_Percentage: amazon_ses_Allowed_Sending_Quota_Percentage
		},
		dataType: "html"
	});
	request.done(function(content) {
		$("#" + target_div).html(content);
	});
}




function test_user_template() {
	var target_div = 'test_user_template_results';
	if ($("#template_options_mode_magic").prop("checked") === true) {
		test_magic_template(); 
	}
	else { 

		$("#" + target_div).html('<p class="label info">Loading...</p>');
		if ($("#" + target_div).is(':hidden')) {
			$("#" + target_div).show();
		}
		var request = $.ajax({
			url: $("#self_url").val(),
			type: "POST",
			cache: false,
			data: {
				flavor: 'cgi_test_user_template',
				template_options_manual_template_url: $("#template_options_manual_template_url").val()
			},
			dataType: "html"
		});
		request.done(function(content) {
			$("#" + target_div).html(content);
		});
	}
}

function test_magic_template() { 

	var target_div = 'test_user_template_results';

	$("#" + target_div).html('<p class="label info">Loading...</p>');
	if ($("#" + target_div).is(':hidden')) {
		$("#" + target_div).show();
	}

	var add_base_href_url = 0; 
	if ($("#template_options_add_base_href").prop("checked") === true) {
		add_base_href_url = 1; 
	}
	var add_app_css = 0; 
	if ($("#template_options_add_app_css").prop("checked") === true) {
		add_app_css = 1; 
	}
	var add_custom_css = 0; 
	if ($("#template_options_add_custom_css").prop("checked") === true) {
		add_custom_css = 1; 
	}

	var include_jquery_lib = 0; 
	if ($("#template_options_include_jquery_lib").prop("checked") === true) {
		include_jquery_lib = 1; 
	}

	var include_app_user_js = 0; 
	if ($("#template_options_include_app_user_js").prop("checked") === true) {
		include_app_user_js = 1; 
	}


	var request = $.ajax({
		url: $("#self_url").val(),
		type: "POST",
		cache: false,
		data: {
			flavor:                                'cgi_test_magic_template_diag_box',
			template_options_template_url:         $('#template_options_magic_template_url').val(), 
			template_options_add_base_href:        add_base_href_url,  
			template_options_base_href_url:        $('#template_options_base_href_url').val(),
			template_options_replace_content_from: $("input:radio[name ='template_options_replace_content_from']:checked").val(),
			template_options_replace_id:           $('#template_options_replace_id').val(), 
			template_options_replace_class:        $('#template_options_replace_class').val(), 
			template_options_add_app_css:          add_app_css, 
			template_options_add_custom_css:       add_custom_css,  
			template_options_custom_css_url:       $('#template_options_custom_css_url').val(),
			template_options_include_jquery_lib:   include_jquery_lib,
			template_options_include_app_user_js:  include_app_user_js
		},
		dataType: "html"
	});
	request.done(function(content) {
		$("#" + target_div).html(content);
	});
	
	window.open(
		$("#self_url").val() + '?flavor=cgi_test_magic_template' + 
		'&template_options_template_url='         + encodeURIComponent($('#template_options_magic_template_url').val()) + 
		'&template_options_add_base_href='    + encodeURIComponent(add_base_href_url) + 
		'&template_options_base_href_url='        + encodeURIComponent($('#template_options_base_href_url').val()) + 
		'&template_options_replace_content_from=' + encodeURIComponent(
			$("input:radio[name ='template_options_replace_content_from']:checked").val()
		) + 
		'&template_options_replace_id='     + encodeURIComponent($('#template_options_replace_id').val()) + 
		'&template_options_replace_class='  + encodeURIComponent($('#template_options_replace_class').val()) + 
		'&template_options_add_app_css='    + encodeURIComponent(add_app_css) +
		'&template_options_add_custom_css=' + encodeURIComponent(add_custom_css) + 
		'&template_options_custom_css_url=' + encodeURIComponent($('#template_options_custom_css_url').val()) + 
		
		'&template_options_include_jquery_lib='   + encodeURIComponent(include_jquery_lib) + 
		'&template_options_include_app_user_js='  + encodeURIComponent(include_app_user_js) + 
		'&template_options_head_content_added_by=' + encodeURIComponent($("#template_options_head_content_added_by option:selected").val()),
 		"magicTemplatetest", 
		"width=640,height=480,scrollbars=yes");

	return false; 
}


function test_CAPTCHA_configuration() {
	var target_div = 'test_CAPTCHA_configuration_results';
	$("#" + target_div).html('<p class="label info">Loading...</p>');
	if ($("#" + target_div).is(':hidden')) {
		$("#" + target_div).show();
	}
	
	var flavor = 'google_recaptcha'; 
	var request = $.ajax({
		url: $("#self_url").val(),
		type: "POST",
		cache: false,
		data: {
			flavor: 'cgi_test_CAPTCHA_Google_reCAPTCHA',
			captcha_params_v2_public_key:  $("#captcha_params_v2_public_key").val(),
			captcha_params_v2_private_key: $("#captcha_params_v2_private_key").val()
		},
		dataType: "html",
		success: function(content) {
			$("#" + target_div).html(content);
			var captchaWidgetId = grecaptcha.render( 'google_recaptcha_example', {
			  'sitekey' : $("#captcha_params_v2_public_key").val()
			});
		},
		error: function(xhr, ajaxOptions, thrownError) {
			console.log('status: ' + xhr.status);
			console.log('thrownError:' + thrownError);
		}, 
	});
}




function installer_checkbox_toggle_option_groups(checkbox_id, target_id){ 
	if ($("#" + checkbox_id).length) {
		if ($("#" + checkbox_id).prop("checked") === true) {
			if ($('#' + target_id).is(':hidden')) {
				$('#' + target_id).show('blind');
			}
		} else {
			if ($('#' + target_id).is(':visible')) {
				$('#' + target_id).hide('blind');
			}
			else { 
			}
		}		
	}
	else { 
	}
}

function installer_dada_root_pass_options() {
	if ($("#dada_pass_use_orig").prop("checked") === true) {
		if ($('#dada_root_pass_fields').is(':visible')) {
			$('#dada_root_pass_fields').hide('blind');
		}
	}
	if ($("#dada_pass_use_orig").prop("checked") === false) {
		if ($('#dada_root_pass_fields').is(':hidden')) {
			$('#dada_root_pass_fields').show('blind');
		}
	}

}

function installer_set_up_global_api_options() { 
	$('#global_api_public_key').val(installer_random_string(21));
	$('#global_api_private_key').val(installer_random_string(41));
}



function installer_toggle_captcha_type_options() { 

	var selected = ''; 
	if($("#captcha_type_default").prop("checked") === true) { 
		selected = 'captcha_type_default'; 
	}
	else if($("#captcha_type_recaptcha").prop("checked") === true) { 
		selected = 'captcha_type_recaptcha'; 		
	}
	else if($("#captcha_type_google_recaptcha").prop("checked") === true) { 
		selected = 'captcha_type_google_recaptcha'; 			
	}
	

	if (
		selected == 'captcha_type_recaptcha'
		|| 
		selected == 'captcha_type_google_recaptcha'		
	) {
		if ($('#recaptcha_settings').is(':hidden')) {
			$('#recaptcha_settings').show('blind');
		}
	} else {
		if ($('#recaptcha_settings').is(':visible')) {
			$('#recaptcha_settings').hide('blind');
		}
	}	
}

function installer_toggle_dada_files_dirOptions() {

	if ($("#dada_files_dir_setup_auto").prop("checked") === true) {
		if ($('#manual_dada_files_dir_setup').is(':visible')) {
			$('#manual_dada_files_dir_setup').hide('blind');
		}
	}
	if ($("#dada_files_dir_setup_manual").prop("checked") === true) {
		if ($('#manual_dada_files_dir_setup').is(':hidden')) {
			$('#manual_dada_files_dir_setup').show('blind');
		}
	}
}

function installer_toggle_template_mode_magic_options() { 
	if ($("#template_options_mode_manual").prop("checked") === true) {
		if ($('#template_mode_magic_options').is(':visible')) {
			$('#template_mode_magic_options').hide('blind');
		}
		if ($('#template_mode_manual_options').is(':hidden')) {
			$('#template_mode_manual_options').show('blind');
		}
	}
	if ($("#template_options_mode_magic").prop("checked") === true) {
		if ($('#template_mode_magic_options').is(':hidden')) {
			$('#template_mode_magic_options').show('blind');
		}
		if ($('#template_mode_manual_options').is(':visible')) {
			$('#template_mode_manual_options').hide('blind');
		}
	}	
}

/*
function installer_toggle_bounce_handler_Connection_Protocol_options() { 
	if ($("#bounce_handler_Connection_Protocol_POP3").prop("checked") === true) {
		if ($('#bounce_handler_Connection_Protocol_IMAP_options').is(':visible')) {
			$('#bounce_handler_Connection_Protocol_IMAP_options').hide('blind');
		}
		if ($('#bounce_handler_Connection_Protocol_POP3_options').is(':hidden')) {
			$('#bounce_handler_Connection_Protocol_POP3_options').show('blind');
		}
	}
	if ($("#bounce_handler_Connection_Protocol_IMAP").prop("checked") === true) {
		if ($('#bounce_handler_Connection_Protocol_IMAP_options').is(':hidden')) {
			$('#bounce_handler_Connection_Protocol_IMAP_options').show('blind');
		}
		if ($('#bounce_handler_Connection_Protocol_POP3_options').is(':visible')) {
			$('#bounce_handler_Connection_Protocol_POP3_options').hide('blind');
		}
	}
}
*/


function installer_random_string(string_length) {
  var text = "";
  var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

  for (var i = 0; i < string_length; i++)
    text += possible.charAt(Math.floor(Math.random() * possible.length));

  return text;
}




function installer_move_installer_dir(file_chmod) {
	
	$("#move_results").hide();
	var request = $.ajax({
		url: $("#self_url").val(),
		type: "POST",
		cache: false,
		data: {
			flavor: 'move_installer_dir_ajax',
			file_chmod: file_chmod
		},
		dataType: "html"
	});
	request.done(function(content) {
		$("#move_results").html(content);
		$("#move_results").show('blind');
	});
}

function changeDisplayState(target, state) {
	if (state == 'show') {
		if ($('#' + target).is(':hidden')) {
			$('#' + target).show('blind');
		}
	} else {
		if ($('#' + target).is(':visible')) {
			$('#' + target).hide('blind');
		}
	}
}

});

