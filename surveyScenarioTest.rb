require "capybara"
require "capybarista"
#require "JSON"

Capybara.ignore_hidden_elements = true
Capybara.configure do |config|
  config.default_wait_time = 2
end

if ARGV.size < 1
	puts "Program aborted - add a URL as a command-line argument"
	exit
end
surveyUrl = ARGV[0]


class SurveyFiller

	attr_accessor :session

	def initialize(session)
		@session = session
	end

	def goToLastPage(url)
		session.visit url
		begin
			while session.has_css?(".gform_body") # waits for ajax to finish
				begin
					if session.first(:css, ".gform_next_button")
						session.find(:css, '.gform_next_button').click
					elsif session.first(:css, "input[type='submit']")
						break
					end
				rescue
					
				end
			end
		rescue
			puts "goToLastPage method error - most likely nothing to worry about"
		end
		return self
	end

	def considerationTest(url)
		session.visit url

		# find all consideration options - consideration question must have class 'consideration'
		considerationInputs = session.all(:css, '.consideration input', :visible => false)
		considerationIdArray =  considerationInputs.map {|c| c[:id]}
		considerationLength = considerationIdArray.length

		# find all guides options - guides question must have class 'guides'
		guidesInputs = session.all(:css, '.guides input', :visible => false)
		guidesIdArray =  guidesInputs.map {|c| c[:id]}

		# find first daf option - daf question must have class 'daf'
		dafInputs = session.all(:css, '.daf .gfield_radio li:first-child input', :visible => false)
		dafIdArray =  dafInputs.map {|c| c[:id]}

		puts "consideration options found: #{considerationLength}"

		# submit survey twice for each consideration question
		considerationLength.times do |i|
			2.times do |j|
				goToLastPage(url)

				# select a consideration option
				@selectedConsideration = considerationIdArray[i]
				session.execute_script("jQuery('#'+'#{@selectedConsideration}').prop('checked',true); ")
				selectedString = session.execute_script("return jQuery('#'+'#{@selectedConsideration}').parent().text()")
				puts "consideration option selected: #{selectedString}"

				# first loop of each consideration option, select no guides, otherwise choose one randomly
				if j == 1
					@selectedGuide = guidesIdArray.sample
					session.execute_script("jQuery('#'+'#{@selectedGuide}').prop('checked',true); ")
					
					# if second consideration option is selected, select ALL guides
					if i == 1
						puts "guides selected: " 
						guidesIdArray.each do |g|
							@selectedGuide = g
							session.execute_script("jQuery('#'+'#{@selectedGuide}').prop('checked',true); ")
							selectedString = session.execute_script("return jQuery('#'+'#{@selectedGuide}').parent().text()")
							puts selectedString
						end
					else
						selectedString = session.execute_script("return jQuery('#'+'#{@selectedGuide}').parent().text()")
						puts "guides selected: #{selectedString}"
					end
				else
					puts "no guides selected"
				end

				# randomly select the first option of the daf questions
				if [0, 1].sample == 1
					dafIdArray.each do |d|
						@selectedDaf = d
						session.execute_script("jQuery('#'+'#{@selectedDaf}').prop('checked',true); ")
						selectedString = session.execute_script("return jQuery('#'+'#{@selectedDaf}').parent().text()")
						puts "daf option selected: #{selectedString}"
					end
				end

				# fill in random input fields
				inputFill
				# fill in all required input fields
				requiredInputFill
				# submit the survey
				surveySubmit
			end
		end

		# leave consideration blank to test 'default' thank-you message
		goToLastPage(url)
		puts "no consideration/guides/daf options selected"
		requiredInputFill
		surveySubmit
	end
	


	def surveySubmit
		if session.first(:css, "input[type='submit']")
			session.find(:css, "input[type='submit']").click
			sleep 3
		end
		puts "press ENTER to continue"
		puts "____________________________________________________________________________________________"
		$stdin.gets
	end

	def inputFill
		allInputs = session.all(:css, 'input[type="text"], textarea', :visible => false)
		inputIdArray = allInputs.map {|c| c[:id]}
		times = inputIdArray.length
		timesToFill = rand(times*2).ceil
		timesToFill.times do |i|
			@sampledID = inputIdArray.sample
			@randomString = (0...8).map { (65 + rand(26)).chr }.join
			session.execute_script("jQuery('#'+'#{@sampledID}').val('#{@randomString}').attr('value', '#{@randomString}'); ")
		end
	end
	def requiredInputFill
		requiredInputs = session.all(:css, '.gfield_contains_required input', :visible => false)
		inputIdArray = requiredInputs.map {|c| c[:id]}
		inputIdArray.each{|i|
			@sampledID = i
			@randomString = (0...8).map { (65 + rand(26)).chr }.join
			session.execute_script("jQuery('#'+'#{@sampledID}').val('#{@randomString}').attr('value', '#{@randomString}'); ")
		}
		# fill in email address
		@randomString = (0...8).map { (65 + rand(26)).chr }.join
		session.execute_script("var emailLabel = jQuery('.gfield_contains_required label').filter(function(){return jQuery(this).text().toLowerCase().indexOf('email') >= 0});
								emailid = emailLabel.parent().attr('id');
								jQuery('#'+emailid+' input').val('#{@randomString}'+'@MSsurveyBot.com').attr('value', '#{@randomString}'+'@MSsurveyBot.com'); ")
		# fill in zip code
		@randomString = (0...5).map { (48 + rand(9)).chr }.join
		session.execute_script("var zipLabel = jQuery('label').filter(function(){return jQuery(this).text().toLowerCase().indexOf('zip') >= 0});
								zipid = zipLabel.parent().attr('id');
								jQuery('#'+zipid+' input').val('#{@randomString}').attr('value', '#{@randomString}'); ")
		# select options from country and state dropdowns
		session.execute_script("var countryLabel = jQuery('select').parent().parent().children('label').filter(function(){return jQuery(this).text().toLowerCase().indexOf('country') >= 0});
								countryLabel.parent().addClass('country')
								var countryid = countryLabel.parent().attr('id');
								jQuery('#'+countryid+' select').prop('selectedIndex', 4);

								var stateLabel = jQuery('select').parent().parent().children('label').filter(function(){return jQuery(this).text().toLowerCase().indexOf('state') >= 0});
								stateLabel.parent().addClass('state')
								var stateid = stateLabel.parent().attr('id');
								jQuery('#'+stateid+' select').prop('selectedIndex', 4);")
		# make sure country and state values are two characters long
		if session.first(:css, ".country select").value.length != 2
			puts "warning: the country dropdown option's value is not two characters"
		end
		if session.first(:css, ".state select").value.length != 2
			puts "warning: the state dropdown option's value is not two characters"
		end
	end

end


session = Capybara::Session.new :selenium

surveyBot = SurveyFiller.new(session)


	# go to the last page and fill in random checkboxes
	surveyBot.considerationTest(surveyUrl)
	






